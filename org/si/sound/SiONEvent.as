//----------------------------------------------------------------------------------------------------
// Events for SiON
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound {
    import flash.events.Event;
    import flash.media.Sound;
    import flash.utils.ByteArray;
    
    
    
    
    /** SiON Event class.
     */
    public class SiONEvent extends Event 
    {
    // constants
    //----------------------------------------
        public static const COMPILE_PROGRESS:String = 'compileProgress';
        public static const COMPILE_COMPLETE:String = 'compileComplete';
        public static const STREAM:String           = 'stream';
        public static const STREAM_START:String     = 'streamStart';
        public static const STREAM_STOP:String      = 'streamStop';
        
        
        
        
    // valiables
    //----------------------------------------
        // driver
        private var _driver:SiONDriver;
        
        // streaming buffer
        private var _streamBuffer:ByteArray;
        
        
        
        
    // properties
    //----------------------------------------
        /** Sound driver. */
        public function get driver():SiONDriver { return _driver; }
        
        /** Sound data. */
        public function get data():SiONData { return _driver.data; }
        
        /** ByteArray of sound stream. This is available only in STREAM event. */
        public function get streamBuffer():ByteArray { return _streamBuffer; }
        
        
        
        
    // functions
    //----------------------------------------
        /** Creates an SiONEvent object to pass as a parameter to event listeners. */
        public function SiONEvent(type:String, driver:SiONDriver, streamBuffer:ByteArray = null, bubbles:Boolean = false, cancelable:Boolean = false)
        {
            super(type, bubbles, cancelable);
            _driver = driver;
            _streamBuffer = streamBuffer;
        }
        
        
        /** clone. */
        override public function clone() : Event
        { 
            return new SiONEvent(type, driver, streamBuffer, bubbles, cancelable);
        }
    }
}

