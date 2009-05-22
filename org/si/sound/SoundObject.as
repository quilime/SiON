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
        
        /** Sound length uint in 16th beat, 0 sets inifinity length. @default 0. */
        public length:Number;
        
        /** Sound delay uint in 16th beat. @default 0. */
        public delay:Number;
        
        /** Synchronizing quantizing uint in 16th beat. (0:No synchronization, 1:sync.with 16th, 4:sync.with 4th). @default 0. */
        public quantize:Number;
        
        /** @private [internal uses] parent container */
        internal var _parent:SoundObjectContainer;
        
        /** driver instance to access directly */
        protected var _driver:SiONDriver;
        
        /** total volume of all ancestors */
        protected var _totalVolume:Number;
        /** volume of this sound object */
        protected var _thisVolume:Number
        /** total panning of all ancestors */
        protected var _totalPan:Number;
        /** panning of this sound object */
        protected var _thisPan:Number
        /** total mute flag of all ancestors */
        protected var _totalMute:Boolean;
        /** mute flag of this sound object */
        protected var _thisMute:Boolean;
        
        // next track id
        static private var _nextTrackID:int=0;
        
        
        
        
    // properties
    //----------------------------------------
        /** SiONDriver instrance to operate. */
        public function get driver() : SiONDriver { return _driver; }
        
        /** Mute. */
        public function get mute() : Boolean { return _thisMute; }
        public function set mute(m:Boolean) : void { 
            _thisMute = m;
            _updateMute();
        }
        
        /** Volume (0:Minimum - 1:Maximum). */
        public function get volume() : Number { return _thisVolume; }
        public function set volume(v:Number) : void {
            _thisVolume = v;
            _updateVolume();
            _limitVolume();
        }
        
        /** Panning (-1:Left - 0:Center - +1:Right). */
        public function get pan() : Number { return _thisPan; }
        public function set pan(p:Number) : void {
            _thisPan = p;
            _updatePan();
            _limitPan();
        }
        
        /** parent container. */
        public function get parent() : SoundObjectContainer { return _parent; }
        
        /** next track id to use */
        static protected function get nextTrackID() : int {
            return (_nextTrackID++);
        }
        
        
        
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
        
        
        
        
    // oprate ancestor
    //----------------------------------------
        /** @private [internal use] */
        internal function _setParent(parent:SoundObject) : void
        {
            if (_parent != null) _parent.removeChild(this);
            _parent = parent;
            _updateMute();
            _updateVolume();
            _limitVolume();
            _updatePan();
            _limitPan();
        }
        
        
        /** @private [internal use] */
        internal function _updateMute() : void
        {
            if (_parent) _totalMute = _parent._totalMute || _thisMute;
            else _totalMute = _thisMute;
        }
        
        
        /** @private [internal use] */
        internal function _updateVolume() : void
        {
            if (_parent) _totalVolume = _parent._totalVolume * _thisVolume;
            else _totalVolume = _thisVolume;
        }
        
        
        /** @private [internal use] */
        internal function _limitVolume() : void
        {
            if (_totalVolume < 0) _totalVolume = 0;
            else if (_totalVolume > 1) _totalVolume = 1;
        }
        
        
        /** @private [internal use] */
        internal function _updatePan() : void
        {
            if (_parent) _totalPan = (_parent._totalPan + _thisPan) * 0.5;
            else _totalPan = _thisPan;
        }
        
        
        /** @private [internal use] */
        internal function _limitPan() : void
        {
            if (_totalPan < -1) _totalPan = -1;
            else if (_totalPan > 1) _totalPan = 1;
        }
    }
}


