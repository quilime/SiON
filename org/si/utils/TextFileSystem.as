package org.si.utils {
    import flash.events.*;
    import flash.net.SharedObject;
    import flash.net.SharedObjectFlushStatus;
    import flash.net.FileReference;
    
    
    /** Tex file managiment system by xml. */
    public class TextFileSystem
    {
    // constants
    //------------------------------------------------------------
        static public const FAILURE:int = 0;
        static public const SUCCESS:int = 1;
        static public const FILE_EXIST:int = 2;
        static public const FILE_NOT_EXIST:int = 3;
        
        
        
    // variables
    //------------------------------------------------------------
        private var _fileSystem:XML;
        private var _currentDrive:XML;
        private var _currentDirectory:XML;
        private var _homeDirectory:XML;
        
        static private var _sharedObjectName:String = "simos_file_system";
        
        
        
        
    // properties
    //------------------------------------------------------------        
        public function get xml() : XML
        {
            return _fileSystem;
        }
        
        
        
        
    // constructor
    //------------------------------------------------------------
        function TextFileSystem()
        {
        }
        
        
        
        
    // initialize
    //------------------------------------------------------------
        /** Initialize */
        public function initialize() : void
        {
            _fileSystem = <simos_fs><dir name='' root='true' protected='true'/></simos_fs>;
            _currentDrive = _fileSystem.dir.(@root == 'true')[0];
            _currentDirectory = _currentDrive;
            _homeDirectory = _currentDirectory;
        }
        
        
        /** Load files as a cookie */
        public function loadCookie() : Boolean
        {
            try {
                var so:SharedObject = SharedObject.getLocal(_sharedObjectName);
                if (so.data.ttfsXML) {
                    _fileSystem = so.data.ttfsXML;
                    _currentDrive = _fileSystem.dir.(@root == 'true')[0];
                    if (_currentDrive.dir.length() == 0) return false;
                    _currentDirectory = (_currentDrive.dir.length() > 0) ? _currentDrive.dir[0] : _currentDrive;
                    _homeDirectory = _currentDirectory;
                    return true;
                }
            } catch (e:Error) {
                return false;
            }
            return false;
        }
        
        
        /** Save files as a cookie */
        public function saveCookie() : Boolean
        {
            try {
                var so:SharedObject = SharedObject.getLocal(_sharedObjectName);
                so.data.ttfsXML = _fileSystem;
                return (so.flush() == SharedObjectFlushStatus.FLUSHED);
            }
            catch (e:Error) {
                return false;
            }
            return true;
        }
        
        
        /** Clear cookie */
        public function clearCookie() : void
        {
            var so:SharedObject = SharedObject.getLocal("SiMOSFileSystem");
            so.clear();
        }
        
        
        
        
    // support
    //------------------------------------------------------------
        /** Parse path.
         *  @param path Path string.
         *  @param createNewElem When the path is not exist and this argument is true, create new XML element on that path.
         *  @param getParentDirectory When true, get parent directory element of specifyed path.
         *  @return XML element of specifyed path. Returns null when its not found.
         */
        public function parsePath(path:String, createNewElem:Boolean, getParentDirectory:Boolean=false) : XML
        {
            var elem:XML, found:Boolean, isDir:Boolean, i:int, tkn:String;

            switch (path) {
            case "/":  return _currentDrive;
            case ".":  return _currentDirectory;
            case "..": return _currentDirectory.parent();
            }
            
            var idx:int = (path.indexOf('/') == 0) ? 1 : 0;
            var ptr:XML = (idx == 1) ? _currentDrive : _currentDirectory;
            
            while (idx != -1) {
                // get token
                i = path.indexOf('/', idx);
                if (i == -1) {
                    // file
                    isDir = false;
                    tkn = path.substring(idx);
                    idx = -1;
                    if (getParentDirectory) return ptr;
                }
                else if (i == path.length-1) {
                    // directory
                    isDir = true;
                    tkn = path.substring(idx, i);
                    idx = -1;
                    if (getParentDirectory) return ptr;
                } else {
                    // path
                    isDir = true;
                    tkn = path.substring(idx, i);
                    idx = i+1;
                }
                
                // move pointer
                if (tkn == '..') {
                    ptr = ptr.parent();
                    if (ptr.localName() != 'dir') return null;
                } else 
                if (tkn == '.') {
                    // do nothing
                } else {
                    found = false;
                    for each (elem in ptr.children()) {
                        found = ((elem.localName() == 'dir' || elem.localName() == 'file') && elem.@name == tkn);
                        if (found) {
                            // found this token
                            ptr = elem;
                            break;
                        }
                    }
                    if (!found) {
                        if (createNewElem) {
                            var tag:String = (isDir) ? "dir" : "file";
                            elem = <{tag} name={tkn}/>;
                            ptr.appendChild(elem);
                            ptr = elem;
                        } else {
                            // token is not found
                            return null;
                        }
                    }
                }
            }
            return ptr;
        }
        

        /** Abstruct directory from path.
         *  @param name Path string.
         */
        public function getDirectoryName(name:String) : String
        {
            var i:int = name.lastIndexOf('/');
            return (i == -1) ? '' : name.substring(0,i+1);
        }
        
        
        /** Abstruct file name from path.
         *  @param name Path string.
         */
        public function getFileName(name:String) : String
        {
            var i:int = name.lastIndexOf('/');
            return (i == -1) ? name : name.substring(i+1);
        }
        
        
        /** Complement file name in current directory.
         *  @param name Imcompleted file name.
         *  @return Completed file name. Returns same as argument when it cannot be completed.
         */
        public function complementName(name:String) : String
        {
            var dir:XML, elem:XML;
            var str:String = getFileName(name);
            dir = (str == name) ? _currentDirectory : parsePath(name, false, true);
            if (dir == null) return name;
            
            var cand:String = null, fileName:String;
            for each (elem in dir.children()) {
                if (elem.@name.length() > 0) {
                    fileName = elem.@name[0];
                    if (_and(fileName, str) == str.length) {
                        if (cand) {
                            cand = cand.substr(0, _and(cand, fileName));
                        } else {
                            cand = fileName;
                        }
                    }
                }
            }
            return (cand) ? (getDirectoryName(name) + cand) : name;
            
            function _and(s1:String, s2:String) : int {
                var imax:int = (s1.length < s2.length) ? s1.length : s2.length;
                for (var i:int=0; i<imax; i++) {
                    if (s1.charAt(i) != s2.charAt(i)) return i;
                }
                return i;
            }
        }
        
        
        
        
    // file operations
    //------------------------------------------------------------
        /** Load text file 
         *  @param filePath File path from current directory.
         *  @param createNewFile Create new file when it doesnt exist.
         */
        public function loadTextFile(filePath:String, createNewFile:Boolean) : String
        {
            if (filePath == "") return null;
            var file:XML = parsePath(filePath, createNewFile);
            return (file == null) ? null : (file.text());
        }
        
        
        /** Save text file 
         *  @param filePath File path from current directory.
         *  @param text Saving text.
         *  @param forceOverwrite Overwrite when it already exists.
         */
        public function saveTextFile(filePath:String, text:String, forceOverwrite:Boolean = false) : int
        {
            if (filePath == "") return FAILURE;
            var file:XML = parsePath(filePath, true);
            if (file == null) return FAILURE;
            if (file.text() != undefined && !forceOverwrite) return FILE_EXIST;
            if (file.localName() != "file") return FAILURE;
            file.children()[0] = text;
            return SUCCESS;
        }
        
        
        /** Make directory
         *  @param dirPath Directory path and name to create.
         */
        public function mkdir(dirPath:String) : int
        {
            var dir:XML = parsePath(dirPath, true);
            if (dir == null ||
                dir.localName != 'dir' ||
                dir.children().length() > 0 ||
                dir.@protected == 'true') return FAILURE;
            dir.setLocalName("dir");
            return SUCCESS;
        }
        
        
        /** Copy file
         *  @param srcPath File path of source file from current directory.
         *  @param dstPath File path of distination file from current directory.
         *  @param forceOverwrite Overwrite when it already exists.
         *  @param moveFile Delete original after copy.
         */
        public function cp(srcPath:String, dstPath:String, forceOverwrite:Boolean = false, moveFile:Boolean = false) : int
        {
            var src:XML = parsePath(srcPath, false),
                dstDir:XML = parsePath(dstPath, false, true),
                dstFileName:String = getFileName(dstPath);
            if (src == null || dstDir == null) return FILE_NOT_EXIST;
            if (!forceOverwrite && dstDir.file.(@name==dstFileName).length() > 0) return FILE_EXIST;
            var clone:XML = src.copy();
            clone.@name = dstFileName;
            dstDir.appendChild(clone);
            if (moveFile) {
                var srcFileName:String = getFileName(srcPath);
                delete src.parent().file.(@name==srcFileName)[0];
            }
            return SUCCESS
        }
        
        
        /** Remove file. You cannot specify path.
         *  @param fileName File path of source file from current directory.
         */
        public function rm(fileName:String) : int
        {
            if (fileName == '*') {
                while (_currentDirectory.file.length()>0) {
                    delete _currentDirectory.file[0];
                }
                return SUCCESS;
            }
            var list:XMLList = _currentDirectory.file.(@name==fileName);
            if (list.length() == 0) return FAILURE;
            if (list[0].@protected == 'true') return FAILURE;
            delete list[0];
            return SUCCESS;
        }
        
        
        /** remove directory */
        public function rmdir(dirName:String) : int
        {
            var list:XMLList = _currentDirectory.dir.(@name=dirName);
            if (list.length() == 0) return FAILURE;
            if (list[0].children().length() > 0) return FILE_EXIST;
            delete list[0];
            return SUCCESS;
        }
        
        
        /** return current directory */
        public function pwd() : String
        {
            var cd:XML = _currentDirectory;
            var ret:String = "";
            while (cd.@root != "true") {
                ret = cd.@name[0] + "/" + ret;
                cd = cd.parent();
            }
            return "/" + ret;
        }
        
        
        /** list current directorys files */
        public function ls() : Array
        {
            var list:Array = [];
            for each (var elem:XML in _currentDirectory.children()) {
                list.push(elem);
            }
            return list.sortOn("@name");
        }
        
        
        /** current directory */
        public function cd(arg:String) : int
        {
            if (arg == null) {
                _currentDirectory = _homeDirectory;
            } else {
                var file:XML = parsePath(arg, false);
                if (file == null || file.localName() != 'dir') return FAILURE;
                _currentDirectory = file;
            }
            return SUCCESS;
        }
        
        
        
        
    // for Flash player 10
    //------------------------------------------------------------
        private var fileReference:FileReference = new FileReference();
        
        
        public function importXML(parentDir:String=null, type:String=null, onImported:Function=null) : void
        {
            var dir:XML = (parentDir) ? parsePath(parentDir, true) : _currentDirectory;
            if (dir == null || dir.localName() != "dir") { onImported(null); return; }
            _import(onComplete);
            
            function onComplete() : void {
                var file:XML = new XML(fileReference.data.readUTFBytes(fileReference.data.length));
                if (type && file.localName() != type) {
                    onImported(null);
                    return;
                }
                if (file.@name.length() == 0) { file.@name = "imported"; }
                if (file.@protected.length() > 0) { delete file.@protected[0]; }
                var newFileName:String = String(file.@name[0]);
                var count:int = 0;
                while (dir.children().(@name==newFileName).length() > 0) {
                    count++;
                    newFileName = String(file.@name[0]) + String(count);
                }
                file.@name = newFileName;
                dir.appendChild(file);
                if (onImported != null) {
                    onImported(file);
                }
            }
        }
        
        
        public function exportXML(path:String=null, defaultName:String=null) : void
        {
            var dir:XML = (path) ? parsePath(path, false) : _currentDirectory;
            if (dir == null) return;
            var fileName:String = (dir.@name[0].length > 0) ? String(dir.@name[0]) : (defaultName) ? defaultName : "ttfs";
            fileReference.save(dir, fileName+".xml");
        }
        
        
        private function _import(onComplete:Function) : void
        {
            fileReference.addEventListener(Event.SELECT, _onSelect);
            fileReference.addEventListener(Event.CANCEL, _onCancel);
            fileReference.browse();
            
            function $remove() : void {
                fileReference.removeEventListener(Event.SELECT, _onSelect);
                fileReference.removeEventListener(Event.CANCEL, _onCancel);
            }
            
            function _onSelect(e:Event) : void {
                $remove();
                fileReference.addEventListener(Event.COMPLETE,        __onComplete);
                fileReference.addEventListener(IOErrorEvent.IO_ERROR, __onError);
                fileReference.load();
                
                function $$remove() : void {
                    fileReference.removeEventListener(Event.COMPLETE,        __onComplete);
                    fileReference.removeEventListener(IOErrorEvent.IO_ERROR, __onError);
                }
                
                function __onComplete(e:Event) : void {
                    $$remove();
                    onComplete();
                }
                
                function __onError(e:IOErrorEvent) : void {
                    $$remove();
                }
            }
            
            function _onCancel(e:Event) : void {
                $remove();
            }
        }
    }
}

