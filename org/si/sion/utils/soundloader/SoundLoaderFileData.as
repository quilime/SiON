//----------------------------------------------------------------------------------------------------
// File Data class for SoundLoader
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sion.utils.soundloader {
    import flash.net.*;
    import flash.media.*;
    import flash.utils.*;
    import flash.system.*;
    import flash.events.*;
    import flash.display.*;
    import org.si.sion.module.ISiOPMWaveInterface;
    import org.si.sion.module.SiOPMWavePCMData;
    import org.si.sion.module.SiOPMWaveSamplerData;
    import org.si.utils.ByteArrayExt;
    import org.si.sion.utils.soundfont.*;
    import org.si.sion.utils.SoundClass;
    import org.si.sion.utils.PCMSample;
    
    
    /** File Data class for SoundLoader */
    public class SoundLoaderFileData 
    {
    // valiables
    //----------------------------------------
        /** @private type converting table */
        static internal var _ext2typeTable:* = {
            "mp3" : "mp3",
            "wav" : "wav",
            "mp3bin" : "mp3bin",
            "swf" : "img",
            "png" : "img",
            "gif" : "img",
            "jpg" : "img",
            "img" : "img",
            "bin" : "bin",
            "txt" : "txt",
            "var" : "var",
            "ssf" : "ssf",
            "ssfpng" : "ssfpng",
            "b2snd" : "b2snd"
        }
        
        
        private var _dataID:String;
        private var _content:*;
        private var _url:String;
        private var _type:String;
        private var _checkPolicyFile:Boolean;
        private var _bytesLoaded:int, _bytesTotal:int;
        private var _loader:Loader, _sound:Sound, _urlLoader:URLLoader, _fontLoader:SiONSoundFontLoader, _byteArray:ByteArray;
        private var _soundLoader:SoundLoader;
        
        // SiON setting data
        private var _target:ISiOPMWaveInterface;
        private var _isPCM:Boolean;
        private var _voiceIndex:int;
        private var _startPoint:int;
        private var _endPoint:int;
        private var _loopPoint:int;
        private var _channelCount:int;
        // for PCM module
        private var _samplingNote:Number;
        private var _keyRangeFrom:int;
        private var _keyRangeTo:int;
        // for Sampler
        private var _ignoreNoteOff:Boolean;
        private var _pan:int;
        
        
        
        
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
        function SoundLoaderFileData(soundLoader:SoundLoader, id:String, url:String, byteArray:ByteArray, ext:String, checkPolicyFile:Boolean)
        {
            this._dataID = id;
            this._soundLoader = soundLoader;
            this._url = url;
            this._type = _ext2typeTable[ext];
            this._checkPolicyFile = checkPolicyFile;
            this._bytesLoaded = 0;
            this._bytesTotal = 0;
            this._content = null;
            this._sound = null;
            this._loader = null;
            this._urlLoader = null;
            this._byteArray = byteArray;
            this._target = null;
            this._startPoint = 0;
            this._endPoint   = -1;
            this._loopPoint  = -1;
        }
        
        
        
        
    // operation
    //----------------------------------------
        /** Set loading target, this function is for sound font type data.
         *  @param loadingTarget instance to register loaded sound font, SiONDriver, SiONData and SiONVoice are valid object.
         *  @return this instance, null when the data type is not matched
         */
        public function setLoadingTarget(loadingTarget:ISiOPMWaveInterface) : SoundLoaderFileData
        {
            if (_type != "ssf" && _type != "ssfpng") {
                _soundLoader._onError(this);
                return null;
            }
            _target = loadingTarget;
            return this;
        }
        
        
        /** Set PCM wave data after loading, this function is for sound type data.
         *  @param loadingTarget instance to register loaded wave, SiONDriver, SiONData and SiONVoice are valid object.
         *  @param index PCM data number.
         *  @param samplingNote Sampling wave's original note number
         *  @param channelCount channel count of data, 1 for monoral, 2 for stereo.
         *  @param keyRangeFrom Assigning key range starts from (not implemented in current version)
         *  @param keyRangeTo Assigning key range ends at (not implemented in current version)
         *  @param startPoint slicing point to start data. The -1 means skip head silence.
         *  @param endPoint slicing point to end data, The negative value calculates from the end.
         *  @param loopPoint slicing point to repeat data, -1 means no repeat, other negative value sets loop tail samples
         *  @return this instance, null when the data type is not matched
         *  @see #org.si.sion.module.SiOPMWavePCMData.maxSampleLengthFromSound
         *  @see #org.si.sion.SiONDriver.render()
         */
        public function setPCMWave(loadingTarget:ISiOPMWaveInterface, index:int, samplingNote:Number=68, keyRangeFrom:int=0, keyRangeTo:int=127, channelCount:int=2, startPoint:int=-1, endPoint:int=-1, loopPoint:int=-1) : SoundLoaderFileData
        {
            if (_type != "mp3" || _type != "mp3bin" || _type != "b2snd" || _type != "wav") {
                _soundLoader._onError(this);
                return null;
            }
            _target = loadingTarget;
            _voiceIndex = index;
            _isPCM = true;
            _channelCount = channelCount;
            _samplingNote = samplingNote;
            _keyRangeFrom = keyRangeFrom;
            _keyRangeTo = keyRangeTo;
            _startPoint = startPoint;
            _endPoint   = endPoint;
            _loopPoint  = loopPoint;
            return this;
        }
        
        
        /** Set sampler wave data after loading, this function is for sound type data.
         *  @param loadingTarget instance to register loaded wave, SiONDriver, SiONData and SiONVoice are valid object.
         *  @param index note number. 0-127 for bank0, 128-255 for bank1.
         *  @param ignoreNoteOff True to set ignoring note off (one shot).
         *  @param pan pan of this sample [-64 - 64].
         *  @param channelCount channel count of data, 1 for monoral, 2 for stereo.
         *  @param startPoint slicing point to start data. The -1 means skip head silence.
         *  @param endPoint slicing point to end data, The negative value calculates from the end.
         *  @param loopPoint slicing point to repeat data, -1 means no repeat
         *  @return this instance, null when the data type is not matched
         *  @see #org.si.sion.module.SiOPMWaveSamplerData.extractThreshold
         *  @see #org.si.sion.SiONDriver.render()
         */
        public function setSamplerWave(loadingTarget:ISiOPMWaveInterface, index:int, ignoreNoteOff:Boolean=false, pan:int=0, channelCount:int=2, startPoint:int=-1, endPoint:int=-1, loopPoint:int=-1) : SoundLoaderFileData
        {
            if (_type != "mp3" || _type != "mp3bin" || _type != "b2snd" || _type != "wav") {
                _soundLoader._onError(this);
                return null;
            }
            _target = loadingTarget;
            _voiceIndex = index;
            _isPCM = false;
            _channelCount = channelCount;
            _ignoreNoteOff = ignoreNoteOff;
            _pan = pan;
            _startPoint = startPoint;
            _endPoint   = endPoint;
            _loopPoint  = loopPoint;
            return this;
        }
        
        
        
        
    // private functions
    //----------------------------------------
        /** @private */
        internal function load() : Boolean
        {
            if (_content) {
                _setDataToLoadingTarget();
                return false;
            }
            
            switch (_type) {
            case "mp3":
                _addAllListeners(_sound = new Sound());
                _sound.load(new URLRequest(_url), new SoundLoaderContext(1000, _checkPolicyFile));
                break;
            case "img":
            case "ssfpng":
                _loader = new Loader();
                _addAllListeners(_loader.contentLoaderInfo);
                _loader.load(new URLRequest(_url), new LoaderContext(_checkPolicyFile));
                break;
            case "txt":
                _addAllListeners(_urlLoader = new URLLoader());
                _urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
                _urlLoader.load(new URLRequest(_url));
                break;
            case "mp3bin":
            case "bin":
            case "wav":
                _addAllListeners(_urlLoader = new URLLoader());
                _urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
                _urlLoader.load(new URLRequest(_url));
                break;
            case "var":
                _addAllListeners(_urlLoader = new URLLoader());
                _urlLoader.dataFormat = URLLoaderDataFormat.VARIABLES;
                _urlLoader.load(new URLRequest(_url));
                break;
            case "ssf":
                _addAllListeners(_fontLoader = new SiONSoundFontLoader());
                _fontLoader.load(_url);
                break;
            case "b2snd":
                SoundClass.loadMP3FromByteArray(_byteArray, __loadMP3FromByteArray_onComplete);
                break;
            default:
                break;
            }
            
            return true;
        }
        
        
        /** @private */
        internal function listenLoadingStatus(target:*) : Boolean
        {
            _sound = target as Sound;
            _loader = target as Loader;
            _urlLoader = target as URLLoader;
            target = _sound || _urlLoader || (_loader && _loader.contentLoaderInfo);
            if (target) {
                if (target.bytesTotal != 0 && target.bytesTotal == target.bytesLoaded) {
                    _postProcess();
                } else {
                    _addAllListeners(target);
                }
                return true;
            }
            return false;
        }
        
        
        private function _addAllListeners(dispatcher:EventDispatcher) : void 
        {
            dispatcher.addEventListener(Event.COMPLETE, _onComplete, false, _soundLoader._eventPriority);
            dispatcher.addEventListener(ProgressEvent.PROGRESS, _onProgress, false, _soundLoader._eventPriority);
            dispatcher.addEventListener(IOErrorEvent.IO_ERROR, _onError, false, _soundLoader._eventPriority);
            dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, _onError, false, _soundLoader._eventPriority);
        }
        
        
        private function _removeAllListeners() : void 
        {
            var dispatcher:EventDispatcher = _sound || _urlLoader || _fontLoader || _loader.contentLoaderInfo;
            dispatcher.removeEventListener(Event.COMPLETE, _onComplete);
            dispatcher.removeEventListener(ProgressEvent.PROGRESS, _onProgress);
            dispatcher.removeEventListener(IOErrorEvent.IO_ERROR, _onError);
            dispatcher.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, _onError);
        }
        
        
        private function _onProgress(e:ProgressEvent) : void
        {
            _soundLoader._onProgress(this, e.bytesLoaded - _bytesLoaded, e.bytesTotal - _bytesTotal);
            _bytesLoaded = e.bytesLoaded;
            _bytesTotal = e.bytesTotal;
        }
        
        
        private function _onComplete(e:Event) : void
        {
            _removeAllListeners();
            _soundLoader._onProgress(this, e.target.bytesLoaded - _bytesLoaded, e.target.bytesTotal - _bytesTotal);
            _bytesLoaded = e.target.bytesLoaded;
            _bytesTotal = e.target.bytesTotal;
            _postProcess();
        }
        
        
        private function _postProcess() : void 
        {
            var currentBICID:String, pcmSample:PCMSample;
            
            switch (_type) {
            case "mp3":
                _content = _sound;
                _setDataToLoadingTarget();
                _soundLoader._onComplete(this);
                break;
            case "wav":
                currentBICID = PCMSample.basicInfoChunkID;
                PCMSample.basicInfoChunkID = "acid";
                pcmSample = new PCMSample().loadWaveFromByteArray(_urlLoader.data); 
                PCMSample.basicInfoChunkID = currentBICID;
                _content = pcmSample;
                _setDataToLoadingTarget();
                _soundLoader._onComplete(this);
                break;
            case "mp3bin":
                SoundClass.loadMP3FromByteArray(_urlLoader.data, __loadMP3FromByteArray_onComplete);
                break;
            case "ssf":
                _content = _fontLoader.soundFont;
                _soundLoader._onComplete(this);
                break;
            case "ssfpng":
                _convertBitmapDataToSoundFont(Bitmap(_loader.content).bitmapData as BitmapData);
                break;
                
            // for ordinary purpose
            case "img":
                _content = _loader.content;
                _soundLoader._onComplete(this);
                break;
            case "txt":
            case "bin":
            case "var":
                _content = _urlLoader.data;
                _soundLoader._onComplete(this);
                break;
            }
        }
        
        
        // set data to loading target
        private function _setDataToLoadingTarget() : void
        {
            switch (_type) {
            case "mp3":
            case "mp3bin":
            case "b2snd":
                _setSoundToLoadingTarget(_content);
                break;
            case "wav":
                _setSoundToLoadingTarget(_content.samples, _content.channels);
                break;
            case "ssf":
            case "ssfpng":
                _setSoundFontToLoadingTarget(_content as SiONSoundFont);
                break;
            }
        }
        
        
        private function _setSoundToLoadingTarget(data:*, srcChannelCount:int=2) : void 
        {
            if (_target) {
                if (_isPCM) {
                    var pcm:SiOPMWavePCMData = _target.setPCMWave(_voiceIndex, data, _samplingNote, _keyRangeFrom, _keyRangeTo, srcChannelCount, _channelCount);
                    pcm.slice(_startPoint, _endPoint, _loopPoint);
                } else {
                    var sample:SiOPMWaveSamplerData = _target.setSamplerWave(_voiceIndex, data, _ignoreNoteOff, _pan, srcChannelCount, _channelCount);
                    sample.slice(_startPoint, _endPoint, _loopPoint);
                }
            }
            _target = null;
        }
        
        
        private function _setSoundFontToLoadingTarget(ssf:SiONSoundFont) : void 
        {
            _target;
        }
        
        
        private function _onError(e:ErrorEvent) : void
        {
            _removeAllListeners();
            __errorCallback(e);
        }
        
        
        private function __loadMP3FromByteArray_onComplete(sound:Sound) : void
        {
            _content = sound;
            _setDataToLoadingTarget();
            _soundLoader._onComplete(this);
        }
        
        
        private function _convertBitmapDataToSoundFont(bitmap:BitmapData) : void
        {
            var bitmap2bytes:ByteArrayExt = new ByteArrayExt(); // convert BitmapData to ByteArray
            _loader = null;
            _fontLoader = new SiONSoundFontLoader();            // convert ByteArray to SWF and SWF to soundList
            _fontLoader.addEventListener(Event.COMPLETE, __convertB2SF_onComplete);
            _fontLoader.addEventListener(IOErrorEvent.IO_ERROR, __errorCallback);
            _fontLoader.loadBytes(bitmap2bytes.fromBitmapData(bitmap));
        }
        
        
        private function __convertB2SF_onComplete(e:Event) : void
        { 
            _content = _fontLoader.soundFont;
            _setDataToLoadingTarget();
            _soundLoader._onComplete(this);
        }
        
        
        private function __errorCallback(e:ErrorEvent) : void
        {
            _soundLoader._onError(this);
        }
    }
}


