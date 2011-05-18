//----------------------------------------------------------------------------------------------------
// Sound Loader
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sion.utils {
    import flash.events.*;
    import flash.net.*;
    import flash.system.*;
    import flash.media.*;
    import flash.display.*;
    import flash.utils.ByteArray;
    
    
    /** Sound Loader. */
    public class SoundLoader extends EventDispatcher
    {
    // constants
    //------------------------------------------------------------
        /** Event id for complete all file loadings, this event is dispatched whether errors appear. */
        static public const COMPLETE_ALL:String = "completeAll";
        
        
        
        
    // valiables
    //------------------------------------------------------------
        /** event priority */
        protected var _eventPriority:int;
        /** loaded sounds */
        protected var _loaded:*;
        /** loading url list */
        protected var _loadingList:*;
        /** total file size */
        protected var _byteTotal:Number;
        /** loaded file size */
        protected var _byteLoaded:int;
        /** loading file count */
        protected var _loadingFileCount:int;
        /** error file count */
        protected var _errorFileCount:int;
        /** loaded pcm count */
        protected var _loadedPCMCount:int;
        
        
        
        
    // properties
    //------------------------------------------------------------
        /** Object to access all Sound instances. */
        public function get content() : * { return _loaded; }

        /** total file size when complete all loadings. */
        public function get byteTotal() : Number { return _byteTotal; }
        
        /** file size currently loaded */
        public function get byteLoaded() : Number { return _byteLoaded; }
        
        /** loading file count, this number is decreased when the file is loaded. */
        public function get loadingFileCount() : int { return _loadingFileCount; }
        
        /** loaded pcm file count */
        public function get loadedPCMCount() : int { return _loadedPCMCount; }
        
        
        
        
    // constructor
    //------------------------------------------------------------
        /** Constructor */
        function SoundLoader(priority:int = 0)
        {
            _eventPriority = priority;
            _loaded = {};
            _loadingList = {};
            _byteTotal = 0;
            _byteLoaded = 0;
            _loadedPCMCount = 0;
            _loadingFileCount = 0;
            _errorFileCount = 0;
        }
        
        
        
        
    // operation
    //------------------------------------------------------------
        /** set sound or swf file's url 
         *  @param url url of file
         *  @param id access key of SoundLoder.content
         *  @param checkPolicyFile LoaderContext.checkPolicyFile
         */
        public function setURL(url:String, id:String=null, checkPolicyFile:Boolean=false) : void
        {
            _loadingList[url] = {id:id, checkPolicyFile:checkPolicyFile};
        }
        
        
        /** load all files specifed by SoundLoder.setURL() */
        public function loadAll() : void
        {
            if (_loadingFileCount != 0) throw new Error("now loading.");
            _loadingFileCount = 0;
            for (var url:String in _loadingList) {
                var fileData:* = _loadingList[url];
                if (url.substr(-4,4) == '.swf') { // swf file
                    var loader:Loader = new Loader();
                    _addAllListeners(loader.contentLoaderInfo);
                    loader.load(new URLRequest(url), new LoaderContext(fileData.checkPolicyFile));
                    fileData["isSWF"] = true;
                    fileData["loader"] = loader;
                } else { // sound file ?
                    var sound:Sound = new Sound();
                    _addAllListeners(sound);
                    sound.load(new URLRequest(url), new SoundLoaderContext(1000, fileData.checkPolicyFile));
                    fileData["isSWF"] = false;
                    fileData["loader"] = sound;
                }
                _loadingFileCount++;
            }
        }
        
        
        
        
    // default handler
    //------------------------------------------------------------
        private function _onProgress(e:ProgressEvent) : void
        {
            _updateTotalBytes();
            dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, _byteLoaded, _byteTotal));
        }
        
        
        private function _onComplete(e:Event) : void
        {
            var url:String = e.target.url as String;
            if (url == null) throw new Error("unknown error. no url ???");
            var fileData:* = _loadingList[url];
            if (!fileData) throw new Error("unknown error. no fileData ???");
            
            var soundList:*, id:String, propName:String, sound:Sound;
            if (fileData.id in _loaded) throw new Error("id confriction. " + fileData.id);
            if (fileData.isSWF) {
                soundList = fileData.loader.content["soundList"];
                if (soundList) {
                    _loaded[fileData.id] = soundList;
                    for (propName in soundList) {
                        sound = soundList[propName] as Sound;
                        if (sound) {
                            id = fileData.id + "." + propName;
                            if (id in _loaded) throw new Error("id confriction. " + id);
                            _loaded[id] = sound;
                            _loadedPCMCount++;
                        }
                    }
                }
            } else {
                _loaded[fileData.id] = fileData.loader as Sound;
                _loadedPCMCount++;
            }
            
            --_loadingFileCount;
            _removeAllListeners(e.target as EventDispatcher);
            _updateTotalBytes();
            dispatchEvent(new Event(Event.COMPLETE));
            if (_loadingFileCount == 0) {
                dispatchEvent(new Event(COMPLETE_ALL));
                _loadingList = {};
            }
        }

    
        private function _onError(e:ErrorEvent) : void
        {
            --_loadingFileCount;
            _errorFileCount++;
            _removeAllListeners(e.target as EventDispatcher);
            dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, e.toString()));
            if (_loadingFileCount == 0) {
                dispatchEvent(new Event(COMPLETE_ALL));
                _loadingList = {};
            }
        }
        
        
        private function _addAllListeners(dispather:EventDispatcher) : void 
        {
            dispather.addEventListener(Event.COMPLETE, _onComplete, false, _eventPriority);
            dispather.addEventListener(ProgressEvent.PROGRESS, _onProgress, false, _eventPriority);
            dispather.addEventListener(IOErrorEvent.IO_ERROR, _onError, false, _eventPriority);
            if (dispather is LoaderInfo) {
                dispather.addEventListener(SecurityErrorEvent.SECURITY_ERROR, _onError, false, _eventPriority);
            }
        }
        
        
        private function _removeAllListeners(dispather:EventDispatcher) : void 
        {
            dispather.removeEventListener(Event.COMPLETE, _onComplete);
            dispather.removeEventListener(ProgressEvent.PROGRESS, _onProgress);
            dispather.removeEventListener(IOErrorEvent.IO_ERROR, _onError);
            if (dispather is LoaderInfo) {
                dispather.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, _onError);
            }
        }
        
        
        private function _updateTotalBytes() : void
        {
            _byteTotal = 0;
            _byteLoaded = 0;
            for each (var fileData:* in _loadingList) {
                var loader:* = fileData["loader"];
                _byteTotal += loader.byteTotal;
                _byteLoaded += loader.byteLoaded;
            }
        }
    }
}

