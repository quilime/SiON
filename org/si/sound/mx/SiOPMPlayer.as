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
        
        private var _lineCommand:Vector.<int> = new Vector.<int>(65);
        private var _lineVectorL:Vector.<Number> = new Vector.<Number>(130);
        private var _lineVectorR:Vector.<Number> = new Vector.<Number>(130);
        
        
        
    // constructor
    //----------------------------------------
        /** Create driver to manage the SiOPM module, compiler and sequencer.
         *  @param channel Channel count. 1 or 2 is available.
         *  @param sampleRate Sampling ratio of wave. 22050 or 44100 is available.
         *  @param bitRate Bit ratio of wave. 8 or 16 is available.
         *  @param bufferSize Buffer size of sound stream. 8192, 4096 or 2048 is available, but no check.
         *  @param throwErrorEvent true; throw ErrorEvent when it errors. false; throw Error when it errors.
         */
        function SiOPMPlayer(channelCount:int=2, sampleRate:int=44100, bitRate:int=16, bufferSize:int=8192, throwErrorEvent:Boolean=true)
        {
            driver = new SiOPMDriver(channelCount, sampleRate, bitRate, bufferSize, throwErrorEvent);
            driver.addEventListener(SiOPMEvent.COMPILE_COMPLETE, _throughEvent);
            driver.addEventListener(SiOPMEvent.COMPILE_PROGRESS, _throughEvent);
            driver.addEventListener(SiOPMEvent.STREAM,           _onStream);
            driver.addEventListener(SiOPMEvent.STREAM_START,     _throughEvent);
            driver.addEventListener(SiOPMEvent.STREAM_STOP,      _throughEvent);
            driver.addEventListener(ErrorEvent.ERROR,            _throughEvent);

            function _throughEvent(e:Event) : void { dispatchEvent(e); }
            for (var i:int=0; i<130; i+=2) {
                _lineCommand[i>>1] = (i) ? 2 : 1;
                _lineVectorL[i] = _lineVectorR[i] = i;
            }
        }
        
        
        private function _onStream(event:SiOPMEvent) : void 
        {
            var data:Vector.<Number> = event.driver.module.output,
                ci:int, i:int, imax:int = data.length, step:int = imax>>7;
            for (ci=1, i=0; ci<130; i+=step, ci+=2) {
                _lineVectorL[ci] = data[i]*16+20;
                _lineVectorR[ci] = data[i+1]*16+60;
            }
            graphics.clear();
            graphics.lineStyle(1, 0xffffff);
            graphics.drawPath(_lineCommand, _lineVectorL);
            graphics.drawPath(_lineCommand, _lineVectorR);
            dispatchEvent(event);
        }
    }
}

