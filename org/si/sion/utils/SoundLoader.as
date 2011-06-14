//----------------------------------------------------------------------------------------------------
// Sound Loader
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sion.utils {
    import flash.events.*;
    import flash.media.*;
    
    
    /** Sound Loader. */
    public class SoundLoader extends EventDispatcher
    {
    // valiables
    //------------------------------------------------------------
        /** loaded sounds */
        protected var _loaded:*;
        /** loading url list */
        protected var _preserveList:Vector.<SoundLoaderFileData>;
        /** total file size */
        protected var _bytesTotal:Number;
        /** loaded file size */
        protected var _bytesLoaded:int;
        /** error file count */
        protected var _errorFileCount:int;
        /** loading file count */
        protected var _loadingFileCount:int;
        /** loaded file count */
        protected var _loadedFileCount:int;
        /** @private event priority */
        internal var _eventPriority:int;
        
        
        
        
    // properties
    //------------------------------------------------------------
        /** Object to access all Sound instances. */
        public function get content() : * { return _loaded; }

        /** total file size when complete all loadings. */
        public function get bytesTotal() : Number { return _bytesTotal; }
        
        /** file size currently loaded */
        public function get bytesLoaded() : Number { return _bytesLoaded; }
        
        /** loading file count, this number is decreased when the file is loaded. */
        public function get loadingFileCount() : int { return _loadingFileCount; }
        
        /** loaded file count */
        public function get loadedFileCount() : int { return _loadedFileCount; }
        
        
        
        
    // constructor
    //------------------------------------------------------------
        /** Constructor */
        function SoundLoader(priority:int = 0)
        {
            _eventPriority = priority;
            _loaded = {};
            _preserveList = new Vector.<SoundLoaderFileData>();
            _bytesTotal = 0;
            _bytesLoaded = 0;
            _loadingFileCount = 0;
            _loadedFileCount = 0;
            _errorFileCount = 0;
        }
        
        
        
        
    // operation
    //------------------------------------------------------------
        /** set sound or swf file's url 
         *  @param url url of file
         *  @param id access key of SoundLoder.content, null to set same as url
         *  @param type file type, "mp3", "wav", "swf" or "png" is available, null to detect automatically. ("img", "bin", "txt" and "var" are available for non-sound files).
         *  @param checkPolicyFile LoaderContext.checkPolicyFile
         *  @return false when the id already loaded
         */
        public function setURL(url:String, id:String=null, type:String=null, checkPolicyFile:Boolean=false) : Boolean
        {
            var lastDotIndex:int = url.lastIndexOf('.'), lastSlashIndex:int = url.lastIndexOf('/');
            if (lastSlashIndex == -1) lastSlashIndex = 0;
            if (lastDotIndex < lastSlashIndex) lastDotIndex = url.length;
            if (id == null) id = url.substr(lastSlashIndex, lastDotIndex-lastSlashIndex);
            if (type == null) type = url.substr(lastDotIndex + 1);
            if (type != "mp3" && type != "swf" && type != "png" && type != "wav" &&
                type != "img" && type != "bin" && type != "txt" && type != "var") {
                throw new Error("unknown file type. : " + url);
            }
            _preserveList.push(new SoundLoaderFileData(this, id, url, type, checkPolicyFile));
            return true;
        }
        
        
        /** load all files specifed by SoundLoder.setURL() 
         *  @return loading file count, 0 when no loading
         */
        public function loadAll() : int
        {
            var count:int = _preserveList.length;
            for (var i:int=0; i<count; i++) _preserveList[i].load();
            _preserveList.length = 0;
            _loadingFileCount += count;
            return count;
        }
        
        
        
        
    // default handler
    //------------------------------------------------------------
        /** @private */
        internal function _onProgress(fileData:SoundLoaderFileData, bytesLoadedDiff:int, bytesTotalDiff:int) : void
        {
            _bytesTotal += bytesTotalDiff;
            _bytesLoaded += bytesLoadedDiff;
            dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, _bytesLoaded, _bytesTotal));
        }
        
        /** @private */
        internal function _onComplete(fileData:SoundLoaderFileData) : void
        {
            _loaded[fileData.dataID] = fileData.data;
            if (fileData.type == "swf" || fileData.type == "png") _registerSoundList(fileData);
            else _loadedFileCount++;
            dispatchEvent(new SoundLoaderEvent(SoundLoaderEvent.COMPLETE, this, fileData));
            if (--_loadingFileCount == 0) {
                dispatchEvent(new SoundLoaderEvent(SoundLoaderEvent.COMPLETE_ALL, this, fileData));
            }
        }
        
        /** @private */
        internal function _onError(fileData:SoundLoaderFileData, e:ErrorEvent) : void
        {
            _errorFileCount++;
            dispatchEvent(new SoundLoaderEvent(SoundLoaderEvent.ERROR, this, fileData));
            if (--_loadingFileCount == 0) {
                dispatchEvent(new SoundLoaderEvent(SoundLoaderEvent.COMPLETE_ALL, this, fileData));
            }
        }
        
        
        private function _registerSoundList(fileData:SoundLoaderFileData) : void {
            var soundList:* = fileData.data, sound:Sound, propName:String;
            for (propName in soundList) {
                sound = soundList[propName] as Sound;
                if (sound) {
                    _loaded[fileData.dataID + "." + propName] = sound;
                    _loadedFileCount++;
                }
            }
        }
    }
}

