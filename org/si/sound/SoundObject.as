//----------------------------------------------------------------------------------------------------
// Sound object
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound {
    import org.si.sion.SiONDriver;
    
    
    /** The SoundObject class is the base class for all objects that can be played sounds on the SiONDriver. 
     */
    public class SoundObject
    {
    // valiables
    //----------------------------------------
        /** Name. */
        public name:String;
        
        /** Sound delay uint in 16th beat. @default 0. */
        public delay:Number;
        
        /** Synchronizing quantizing uint in 16th beat. (0:No synchronization, 1:sync.with 16th, 4:sync.with 4th). @default 0. */
        public quantize:Number;
        
        /** SiONDriver instance to access directly. */
        protected var _driver:SiONDriver;
        
        /** @private [internal uses] parent container */
        internal var _parent:SoundObjectContainer;
        
        
        
        
    // properties
    //----------------------------------------
        /** SiONDriver instrance to operate. */
        public function get driver() : SiONDriver { return _driver; }
        
        /** SoundStage object. */
        public function get stage() : SoundStage { return SoundStage.mutex; }
        
        
        /** Mute. */
        public function get mute() : Boolean { return false; }
        public function set mute(m:Boolean) : void { }
        
        /** Volume (0:Minimum - 1:Maximum). */
        public function get volume() : Number { return 0; }
        public function set volume(v:Number) : void { }
        
        /** Panning (-1:Left - 0:Center - +1:Right). */
        public function get pan() : Number { return 0; }
        public function set pan(p:Number) : void { }
        
        /** parent container. */
        public function get parent() : SoundObjectContainer { return _parent; }
        
        
        
        
    // constructor
    //----------------------------------------
        /** constructor. */
        function SoundObject()
        {
            _driver = SiONDriver.mutex || new SiONDriver();
            _parent = null;
            delay = 0;
            quantize = 0;
            name = "";
        }
        
        
        
        
    // operations
    //----------------------------------------
        /** Play sound. */
        public function play() : void
        {
        }
        
        
        /** Stop sound. */
        public function stop() : void
        {
        }
        
        
        /** Puase sound, resume by play() method. */
        public function pause() : void
        {
        }
    }
}


