//----------------------------------------------------------------------------------------------------
// SiOPM player on mxml
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound.mx {
    import flash.events.*;
    import flash.media.Sound;
    import flash.media.SoundChannel;
    import mx.core.UIComponent;
    import org.si.sound.SiOPMData;
    import org.si.sound.SiOPMEvent;
    import org.si.sound.SiOPMDriver;
    import org.si.sound.driver.SiMMLSequencerTrack;
    
    
    
    
    public class SiOPMPlayer extends UIComponent
    {
    // valiables
    //----------------------------------------
        /** driver. */
        public var driver:SiOPMDriver;
        
        
        
        
    // properties
    //----------------------------------------
        public function get mmlString()    : String       { return driver.mmlString; }
        public function get data()         : SiOPMData    { return driver.data; }
        public function get sound()        : Sound        { return driver.sound; }
        public function get soundChannel() : SoundChannel { return driver.soundChannel; }
        public function get trackCount()   : int          { return driver.trackCount; }
        
        public function get volume()         : Number     { return driver.volume; }
        public function set volume(v:Number) : void       { driver.volume = v; }
        public function get pan()            : Number     { return driver.pan; }
        public function set pan(p:Number)    : void       { driver.pan = p; }
        
        public function get compileTime()     : int       { return driver.compileTime; }
        public function get processTime()     : int       { return driver.processTime; }
        public function get compileProgress() : Number    { return driver.compileProgress; }
        
        public function get isCompiling() : Boolean       { return driver.isCompiling; }
        public function get isPlaying()   : Boolean       { return driver.isPlaying; }
        
        
        
        
    // constructor
    //----------------------------------------
        /** Create driver to manage the SiOPM module, compiler and sequencer.
         *  @param channel Channel count. 1 or 2 is available.
         *  @param sampleRate Sampling ratio of wave. 22050 or 44100 is available.
         *  @param bitRate Bit ratio of wave. 8 or 16 is available.
         *  @param bufferSize Buffer size of sound stream. 8192, 4096 or 2048 is available, but no check.
         *  @param throwErrorEvent true; throw ErrorEvent when it errors. false; throw Error when it errors.
         */
        function SiOPMComponent (channelCount:int=2, sampleRate:int=44100, bitRate:int=16, bufferSize:int=8192, throwErrorEvent:Boolean=true)
        {
            driver = new SiOPMDriver(channelCount, sampleRate, bitRate, bufferSize, throwErrorEvent);
            driver.addEventListener(SiOPMEvent.COMPILE_COMPLETE, _throughEvent);
            driver.addEventListener(SiOPMEvent.COMPILE_PROGRESS, _throughEvent);
            driver.addEventListener(SiOPMEvent.STREAM,           _throughEvent);
            driver.addEventListener(SiOPMEvent.STREAM_START,     _throughEvent);
            driver.addEventListener(SiOPMEvent.STREAM_STOP,      _throughEvent);
            driver.addEventListener(ErrorEvent.ERROR,            _throughEvent);

            function _throughEvent(e:Event) : void { dispatchEvent(e); }
        }
        
        
        
        
    // operations
    //----------------------------------------
        public function compile(mml:String, interval:int=200, storeCompiledData:Boolean=true) : void { driver.compile(mml, interval, true); }
        public function play(data:SiOPMData=null) : void { driver.play(data); }
        public function stop() : void { driver.stop(); }
        public function pause() : void { driver.pause(); }
        public function getTrack(trackIndex:int) : SiMMLSequencerTrack { return driver.getTrack(trackIndex); }
   }
}