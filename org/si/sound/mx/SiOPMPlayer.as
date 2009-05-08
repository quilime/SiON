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
	import org.si.sound.events.*;
    import org.si.sound.SiONData;
    import org.si.sound.SiONDriver;
    
    
    
    
    public class SiOPMPlayer extends UIComponent
    {
    // valiables
    //----------------------------------------
        /** driver. */
        public var driver:SiONDriver;
        
        
        
        
    // constructor
    //----------------------------------------
        /** Create driver to manage the SiOPM module, compiler and sequencer.
         *  @param channel Channel count. 1 or 2 is available.
         *  @param sampleRate Sampling ratio of wave. 22050 or 44100 is available.
         *  @param bitRate Bit ratio of wave. 8 or 16 is available.
         *  @param bufferSize Buffer size of sound stream. 8192, 4096 or 2048 is available, but no check.
         */
        function SiOPMPlayer(bufferSize:int=2048, channelCount:int=2, sampleRate:int=44100, bitRate:int=0)
        {
            driver = new SiONDriver(bufferSize, channelCount, sampleRate, bitRate);
            driver.addEventListener(SiONEvent.STREAM, _onStream);
        }
        
        
        private function _onStream(event:SiONEvent) : void 
        {
        }
    }
}

