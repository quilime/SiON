//----------------------------------------------------------------------------------------------------
// Sound Loader
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sion.utils.soundloader {
    import flash.events.*;
    import flash.media.Sound;
    import flash.utils.ByteArray;
    
    
    // Dispatching events
    /** @eventType org.si.sion.utils.SoundLoaderEvent.COMPLETE_ALL */
    [Event(name="completeAll",      type="org.si.sion.utils.SoundLoaderEvent")]
    /** @eventType org.si.sion.utils.SoundLoaderEvent.COMPLETE */
    [Event(name="complete",         type="org.si.sion.utils.SoundLoaderEvent")]
    /** @eventType org.si.sion.utils.SoundLoaderEvent.ERROR */
    [Event(name="soundLoaderError", type="org.si.sion.utils.SoundLoaderEvent")]
    
    
    /** Sound Loader.</br> 
     *  SoundLoader.setURL() to set loading url, SoundLoader.loadAll() to load all files and SoundLoader.hash to access all loaded files.</br>
     *  @see SoundLoaderEvent
     *  @see #setURL()
     *  @see #loadAll()
     *  @see #hash
     */
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
        /** loaded file data */
        protected var _loadedFileData:*;
        /** @private event priority */
        internal var _eventPriority:int;
        
        /** true to load 'swf' and 'png' type file as 'ssf' and 'ssfpng' @default false */
        protected var _loadImgFileAsSoundFont:Boolean;
        /** true to load 'mp3' type file as 'mp3bin' @default false */
        protected var _loadMP3FileAsBinary:Boolean;
        /** true to remember history @default false */
        protected var _rememberHistory:Boolean
        
        
        
        
    // properties
    //------------------------------------------------------------
        /** Object to access all Sound instances. */
        public function get hash() : * { return _loaded; }

        /** total file size when complete all loadings. */
        public function get bytesTotal() : Number { return _bytesTotal; }
        
        /** file size currently loaded */
        public function get bytesLoaded() : Number { return _bytesLoaded; }
        
        /** loading file count, this number is decreased when the file is loaded. */
        public function get loadingFileCount() : int { return _loadingFileCount + _preserveList.length; }
        
        /** loaded file count */
        public function get loadedFileCount() : int { return _loadedFileCount; }
        
        /** true to load 'swf' and 'png' type file as 'ssf' and 'ssfpng' @default false */
        public function get loadImgFileAsSoundFont() : Boolean { return _loadImgFileAsSoundFont; }
        public function set loadImgFileAsSoundFont(b:Boolean) : void { _loadImgFileAsSoundFont = b; }
        
        /** true to load 'mp3' type file as 'mp3bin' @default false */
        public function get loadMP3FileAsBinary() : Boolean { return _loadMP3FileAsBinary; }
        public function set loadMP3FileAsBinary(b:Boolean) : void { _loadMP3FileAsBinary = b; }
        
        /** true to check ID confirictoin @default false */
        public function get rememberHistory() : Boolean { return _rememberHistory; }
        public function set rememberHistory(b:Boolean) : void { _rememberHistory = b; }
        
        
        
        
    // constructor
    //------------------------------------------------------------
        /** Constructor.
         *  @param eventPriority priority of all events disopatched by this sound loader.
         *  @param loadImgFileAsSoundFont true to load 'swf' and 'png' type file as 'ssf' and 'ssfpng'
         *  @param loadMP3FileAsBinary true to load 'mp3' type file as 'mp3bin'
         *  @param rememberHistory true to check ID confirictoin, 
         */
        function SoundLoader(eventPriority:int=0, loadImgFileAsSoundFont:Boolean=false, loadMP3FileAsBinary:Boolean=false, rememberHistory:Boolean=false)
        {
            _eventPriority = eventPriority;
            _loaded = {};
            _loadedFileData = {};
            _preserveList = new Vector.<SoundLoaderFileData>();
            _bytesTotal = 0;
            _bytesLoaded = 0;
            _loadingFileCount = 0;
            _loadedFileCount = 0;
            _errorFileCount = 0;
            _loadImgFileAsSoundFont = loadImgFileAsSoundFont;
            _loadMP3FileAsBinary = loadMP3FileAsBinary;
            _rememberHistory = rememberHistory;
        }
        
        
        /** output loaded file information */
        override public function toString() : String
        {
            var output:String = "[SoundLoader: " + loadedFileCount + " files are loaded.\n";
            for (var id:String in _loaded) {
                output += "  '" + id + "' : " + _loaded[id].toString() + "\n";
            }
            output += "]"
            return output;
        }
        
        
        
        
    // operation
    //------------------------------------------------------------
        /** set sound or swf file's url 
         *  @param url url of file
         *  @param id access key of SoundLoder.hash. null to set same as file name (without path, with extension).
         *  @param type file type, "mp3", "wav", "ssf", "ssfpng" or "mp3bin" is available, null to detect automatically by file extension. ("swf", "png", "gif", "jpg", "img", "bin", "txt" and "var" are available for non-sound files).
         *  @param checkPolicyFile LoaderContext.checkPolicyFile
         *  @return SoundLoaderFileData instance. SoundLoaderFileData is information class of loading file.
         */
        public function setURL(url:String, id:String=null, type:String=null, checkPolicyFile:Boolean=false) : SoundLoaderFileData
        {
            var lastDotIndex:int = url.lastIndexOf('.'), lastSlashIndex:int = url.lastIndexOf('/'), fileData:SoundLoaderFileData;
            if (lastSlashIndex == -1) lastSlashIndex = 0;
            if (lastDotIndex < lastSlashIndex) lastDotIndex = url.length;
            if (id == null) id = url.substr(lastSlashIndex);
            if (_rememberHistory && id in _loadedFileData && _loadedFileData[id].url == url) {
                fileData = _loadedFileData[id];
            } else {
                if (type == null) type = url.substr(lastDotIndex + 1);
                if (_loadImgFileAsSoundFont) {
                    if (type == 'swf') type = 'ssf';
                    else if (type == 'png') type = 'ssfpng';
                }
                if (_loadMP3FileAsBinary && type == 'mp3') type = 'mp3bin';
                if (!(type in SoundLoaderFileData._ext2typeTable)) throw new Error("unknown file type. : " + url);
                fileData = new SoundLoaderFileData(this, id, url, null, type, checkPolicyFile);
            }
            _preserveList.push(fileData);
            return fileData;
        }
        
        
        /** set ByteArray convert to Sound
         *  @param byteArray ByteArray to convert
         *  @param id access key of SoundLoder.hash
         *  @return SoundLoaderFileData instance. SoundLoaderFileData is information class of loading file.
         */
        public function setByteArraySound(byteArray:ByteArray, id:String) : SoundLoaderFileData
        {
            var fileData:SoundLoaderFileData = new SoundLoaderFileData(this, id, "", byteArray, "b2snd", false);
            _preserveList.push(fileData);
            return fileData;
        }
        
        
        /** load all files specifed by SoundLoder.setURL() 
         *  @return loading file count, 0 when no loading
         */
        public function loadAll() : int
        {
            var count:int = 0;
            for (var i:int=0; i<_preserveList.length; i++) {
                if (_preserveList[i].load()) count++;
            }
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
            if (fileData.dataID) {
                _loadedFileData[fileData.dataID] = fileData;
                _loaded[fileData.dataID] = fileData.data;
            }
            _loadedFileCount++;
            dispatchEvent(new SoundLoaderEvent(SoundLoaderEvent.COMPLETE, this, fileData));
            if (--_loadingFileCount == 0) {
                _bytesLoaded = _bytesTotal;
                dispatchEvent(new SoundLoaderEvent(SoundLoaderEvent.COMPLETE_ALL, this, fileData));
            }
        }
        
        /** @private */
        internal function _onError(fileData:SoundLoaderFileData) : void
        {
            _errorFileCount++;
            dispatchEvent(new SoundLoaderEvent(SoundLoaderEvent.ERROR, this, fileData));
            if (--_loadingFileCount == 0) {
                _bytesLoaded = _bytesTotal;
                dispatchEvent(new SoundLoaderEvent(SoundLoaderEvent.COMPLETE_ALL, this, fileData));
            }
        }
    }
}

