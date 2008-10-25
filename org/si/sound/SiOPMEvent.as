//----------------------------------------------------------------------------------------------------
// Events for SiOPM
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound {
	import flash.events.Event;
	import flash.media.Sound;
    import flash.utils.ByteArray;
	
    
    
    
	/** SiOPM Event class.
     */
	public class SiOPMEvent extends Event 
    {
    // constants
    //----------------------------------------
		public static const COMPILE_PROGRESS:String = 'compileProgress';
		public static const COMPILE_COMPLETE:String = 'compileComplete';
		public static const STREAM:String           = 'stream';
        
        
        
        
    // valiables
    //----------------------------------------
        // driver
        private var _driver:SiOPMDriver;
        
        // streaming buffer
        private var _streamBuffer:ByteArray;
        
		
        
    // properties
    //----------------------------------------
        /** Sound driver. */
        public function get driver():SiOPMDriver { return _driver; }
        
        /** ByteArray of sound stream. This is available only in STREAM event. */
        public function get data():ByteArray { return _streamBuffer; }
        
        
        
        
    // constructor
    //----------------------------------------
        /** Creates an SiOPMEvent object to pass as a parameter to event listeners. */
		public function SiOPMEvent(type:String, driver:SiOPMDriver, streamBuffer:ByteArray = null, bubbles:Boolean = false, cancelable:Boolean = false)
        {
			super(type, bubbles, cancelable);
            _driver = driver;
            _streamBuffer = streamBuffer;
		}
	}
}

