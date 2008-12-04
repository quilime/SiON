//----------------------------------------------------------------------------------------------------
// SiOPM sound channel manager
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound.module {
    /** @private SiOPM sound channel manager */
    public class SiOPMChannelManager
    {
    // constants
    //--------------------------------------------------
        static public const CT_CHANNEL_FM:int = 0;
        static public const CT_EFFECT_DELAY:int = 1;
        static public const CT_MAX:int = 2;
        
        
        
        
    // valiables
    //--------------------------------------------------
        /** class instance of SiOPMChannelBase */
        protected var _channelClass:Class;
        /** channel type */
        protected var _channelType:int;
        /** terminator */
        protected var _term:SiOPMChannelBase;
        /** channel count */
        protected var _length:int;
        
        
        
    // properties
    //--------------------------------------------------
        /** channel count */
        public function get length() : int { return _length; }
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** constructor */
        function SiOPMChannelManager(channelClass:Class, channelType:int)
        {
            _channelType  = channelType;
            _channelClass = channelClass;
            _term = new SiOPMChannelBase(_chip);
            _term._isActive = true;
            _term._next = _term;
            _term._prev = _term;
            _length = 0;
        }
        
        
        
        
    // operations
    //--------------------------------------------------
        /** allocate channels */
        private function _alloc(count:int) : void
        {
            var i:int, newInstance:SiOPMChannelBase, imax:int = count - _length;
            // allocate new channels
            for (i=0; i<imax; i++) {
                newInstance = new _channelClass(_chip);
                newInstance._channelType = _channelType;
                newInstance._isActive = false;
                newInstance._prev = _term._prev;
                newInstance._next = _term;
                newInstance._prev._next = newInstance;
                newInstance._next._prev = newInstance;
                _length++;
            }
        }
        
        
        // get new channel. returns null when the channel count is overflow.
        private function _newChannel(prev:SiOPMChannelBase) : SiOPMChannelBase
        {
            var newInstance:SiOPMChannelBase;
            if (_term._next._isActive) {
                // The head channel is active -> channel overflow.
                if (!_enableExpand) return null;
                // create new channel.
                newInstance = new _channelClass(_chip);
                newInstance._channelType = _channelType;
                _length++;
            } else {
                // The head channel isn't active -> The head is made into a new channel.
                newInstance = _term._next;
                newInstance._prev._next = newInstance._next;
                newInstance._next._prev = newInstance._prev;
            }
            
            // set newInstance to tail and activate.
            newInstance._isActive = true;
            newInstance._prev = _term._prev;
            newInstance._next = _term;
            newInstance._prev._next = newInstance;
            newInstance._next._prev = newInstance;
            
            // initialize
            newInstance.initialize(prev);
            
            return newInstance;
        }
        
        
        // delete channel.
        private function _deleteChannel(ch:SiOPMChannelBase) : void
        {
            ch._isActive = false;
            ch._prev._next = ch._next;
            ch._next._prev = ch._prev;
            ch._prev = _term;
            ch._next = _term._next;
            ch._prev._next = ch;
            ch._next._prev = ch;
        }
        
        
        // initialize all channels
        private function _initializeAll() : void
        {
            var ch:SiOPMChannelBase;
            for (ch=_term._next; ch!=_term; ch=ch._next) {
                ch._isActive = false;
                ch.initialize(null);
            }
        }
        
        
        // reset all channels
        private function _resetAll() : void
        {
            var ch:SiOPMChannelBase;
            for (ch=_term._next; ch!=_term; ch=ch._next) {
                ch._isActive = false;
                ch.reset();
            }
        }
        
        
        
        
    // factory
    //----------------------------------------
        /** module instance */
        static protected var _chip:SiOPMModule;
        /** flag enable to expand */
        static protected var _enableExpand:Boolean;
        /** instances */
        static protected var _channelManagers:Vector.<SiOPMChannelManager>;
        
        
        /** initialize */
        static public function initialize(chip:SiOPMModule, enableExpand:Boolean) : void 
        {
            _chip         = chip;
            _enableExpand = enableExpand;
            _channelManagers = new Vector.<SiOPMChannelManager>(CT_MAX, true);
            _channelManagers[CT_CHANNEL_FM]   = new SiOPMChannelManager(SiOPMChannelFM,          CT_CHANNEL_FM);
            _channelManagers[CT_EFFECT_DELAY] = new SiOPMChannelManager(SiOPMChannelEffectDelay, CT_EFFECT_DELAY);
        }
        
        
        /** initialize all channels */
        static public function initializeAllChannels() : void
        {
            // initialize all channels
            for each (var mng:SiOPMChannelManager in _channelManagers) {
                mng._initializeAll();
            }
        }
        
        
        /** reset all channels */
        static public function resetAllChannels() : void
        {
            // reset all channels
            for each (var mng:SiOPMChannelManager in _channelManagers) {
                mng._resetAll();
            }
        }
        
        
        /** New channel with initializing. */
        static public function newChannel(type:int, prev:SiOPMChannelBase) : SiOPMChannelBase
        {
            return _channelManagers[type]._newChannel(prev);
        }
        
        
        /** Free channel. */
        static public function deleteChannel(channel:SiOPMChannelBase) : void
        {
            _channelManagers[channel._channelType]._deleteChannel(channel);
        }
    }
}


