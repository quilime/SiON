//----------------------------------------------------------------------------------------------------
// File Data class for SoundLoader
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sion.utils {
    import flash.net.*;
    import flash.media.*;
    import flash.system.*;
    import flash.events.*;
    import flash.display.*;
    import org.si.utils.*;
    
    
    /** File Data class for SoundLoader */
    public class SoundLoaderFileData extends EventDispatcher {
    // valiables
    //----------------------------------------
        private var _dataID:String;
        private var _content:*;
        private var _url:String;
        private var _type:String;
        private var _checkPolicyFile:Boolean;
        private var _bytesLoaded:int, _bytesTotal:int;
        private var _loader:Loader, _sound:Sound, _urlLoader:URLLoader;
        private var _soundLoader:SoundLoader;
        
        
        
        
    // properties
    //----------------------------------------
        /** data id */
        public function get dataID() : String { return _dataID; }
        /** loaded data */
        public function get data() : * { return _content; }
        /** url */
        public function get url() : String { return _url; }
        /** data type */
        public function get type() : String { return _type; }
        /** loaded bytes */
        public function get bytesLoaded() : int { return _bytesLoaded; }
        /** total bytes */
        public function get bytesTotal() : int { return _bytesTotal; }
        
        
        
        
    // functions
    //----------------------------------------
        /** @private */
        function SoundLoaderFileData(soundLoader:SoundLoader, id:String, url:String, type:String, checkPolicyFile:Boolean)
        {
            this._dataID = id;
            this._soundLoader = soundLoader;
            this._url = url;
            this._type = type;
            this._checkPolicyFile = checkPolicyFile;
            this._bytesLoaded = 0;
            this._bytesTotal = 0;
            this._content = null;
            this._sound = null;
            this._loader = null;
            this._urlLoader = null;
        }
        
        
        /** @private */
        internal function load() : void
        {
            switch (_type) {
            case "mp3":
                _sound = new Sound();
                _sound.load(new URLRequest(_url), new SoundLoaderContext(1000, _checkPolicyFile));
                break;
            case "png":
            case "swf":
            case "img":
                _loader = new Loader();
                _loader.load(new URLRequest(_url), new LoaderContext(_checkPolicyFile));
                break;
            case "mml":
            case "txt":
                _urlLoader = new URLLoader();
                _urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
                _urlLoader.load(new URLRequest(_url));
                break;
            case "bin":
            case "wav":
                _urlLoader = new URLLoader();
                _urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
                _urlLoader.load(new URLRequest(_url));
                break;
            case "var":
                _urlLoader = new URLLoader();
                _urlLoader.dataFormat = URLLoaderDataFormat.VARIABLES;
                _urlLoader.load(new URLRequest(_url));
                break;
            default:
                break;
            }
            _addAllListeners();
        }
        
        
        private function _addAllListeners() : void 
        {
            var dispatcher:EventDispatcher = _sound || _urlLoader || _loader.contentLoaderInfo;
            dispatcher.addEventListener(Event.COMPLETE, _onComplete, false, _soundLoader._eventPriority);
            dispatcher.addEventListener(ProgressEvent.PROGRESS, _onProgress, false, _soundLoader._eventPriority);
            dispatcher.addEventListener(IOErrorEvent.IO_ERROR, _onError, false, _soundLoader._eventPriority);
            if (_loader || _urlLoader) {
                dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, _onError, false, _soundLoader._eventPriority);
            }
        }
        
        
        private function _removeAllListeners() : void 
        {
            var dispatcher:EventDispatcher = _sound || _urlLoader || _loader.contentLoaderInfo;
            dispatcher.removeEventListener(Event.COMPLETE, _onComplete);
            dispatcher.removeEventListener(ProgressEvent.PROGRESS, _onProgress);
            dispatcher.removeEventListener(IOErrorEvent.IO_ERROR, _onError);
            if (_loader || _urlLoader) {
                dispatcher.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, _onError);
            }
        }
        
        
        private function _onProgress(e:ProgressEvent) : void
        {
            _soundLoader._onProgress(this, e.bytesLoaded - _bytesLoaded, e.bytesTotal - _bytesTotal);
            _bytesLoaded = e.bytesLoaded;
            _bytesTotal = e.bytesTotal;
        }
        
        
        private function _onComplete(e:Event) : void
        {
            var currentBICID:String;
            _removeAllListeners();
            _soundLoader._onProgress(this, e.target.bytesLoaded - _bytesLoaded, e.target.bytesTotal - _bytesTotal);
            _bytesLoaded = e.target.bytesLoaded;
            _bytesTotal = e.target.bytesTotal;
            switch (_type) {
            case 'swf':
                _content = Object(_loader.content)["soundList"];
                _soundLoader._onComplete(this);
                break;
            case 'png':
                _convertBitmapDataToPCMList(Bitmap(_loader.content).bitmapData);
                break;
            case 'mp3':
                _content = _sound;
                _soundLoader._onComplete(this);
                break;
            case 'img':
                _content = _loader.content;
                _soundLoader._onComplete(this);
                break;
            case 'wav':
                currentBICID = PCMSample.basicInfoChunkID;
                PCMSample.basicInfoChunkID = 'acid';
                _content = new PCMSample().loadWaveFromByteArray(_urlLoader.data);
                PCMSample.basicInfoChunkID = currentBICID;
                _soundLoader._onComplete(this);
                break;
            case 'mml':
            case 'txt':
            case 'bin':
            case 'var':
                _content = _urlLoader.data;
                _soundLoader._onComplete(this);
                break;
            }
        }
        
        
        private function _onError(e:ErrorEvent) : void
        {
            _removeAllListeners();
            __errorCallback(e);
        }
        
        
        private function _convertBitmapDataToPCMList(bitmap:BitmapData) : void {
            var bitmap2bytes:ByteArrayExt = new ByteArrayExt(); // convert BitmapData to ByteArray
            var bytes2sounds:Loader = new Loader();             // convert ByteArray to SWF and SWF to soundList
            bytes2sounds.contentLoaderInfo.addEventListener(Event.COMPLETE, __convertB2PL_onComplete);
            bytes2sounds.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, __errorCallback);
            bytes2sounds.loadBytes(bitmap2bytes.fromBitmapData(bitmap));
        }
        
        
        private function __convertB2PL_onComplete(e:Event) : void
        { 
            _content = Object(e.target.content)["soundList"];
            _soundLoader._onComplete(this);
        }
        
        
        private function __errorCallback(e:ErrorEvent) : void
        {
            _soundLoader._onError(this, e);
        }
    }
}


