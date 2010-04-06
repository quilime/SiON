//----------------------------------------------------------------------------------------------------
// Effector chain class
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sound.base {
    import org.si.sion.*;
    import org.si.sion.effector.*;
    import org.si.sion.module.SiOPMStream;
    
    
    /** Effector chain class. */
    public class EffectChain
    {
    // variables
    //--------------------------------------------------
        /** Stream buffer of local effect */
        protected var _effectStream:SiEffectStream;
        /** Effect list */
        protected var _effectList:Array;
        
        
        
    // properties
    //--------------------------------------------------
        /** effector list */
        public function get effectList() : Array { return _effectList; }
        public function set effectList(list:Array) : void {
            _effectList = list;
            if (_effectStream) {
                _effectStream.chain = Vector.<SiEffectBase>(_effectList);
            }
        }
        
        
        /** streaming buffer */
        public function get streamingBuffer() : SiOPMStream {
            return (_effectStream) ? _effectStream.stream : null;
        }
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** constructor
         *  @param list chainning effectors.
         */
        function EffectChain(...list)
        {
            _effectList = list || [];
        }

        
        
        
    // operations
    //--------------------------------------------------
        /** @private [internal] activate local effect. deeper effectors executes first. */
        internal function _activateLocalEffect(depth:int) : void
        {
            var driver:SiONDriver = SiONDriver.mutex;
            if (driver) {
                _effectStream = driver.effector.newLocalEffect(depth, Vector.<SiEffectBase>(_effectList));
            }
        }
        
        
        /** @private [internal] inactivate local effect */
        internal function _inactivateLocalEffect() : void
        {
            if (!_effectStream) return;
            var driver:SiONDriver = SiONDriver.mutex;
            if (driver) {
                driver.effector.deleteLocalEffect(_effectStream);
            }
        }
        
        
        /** set all stream levels by Vector.<int>(8) */
        public function setAllStreamSendLevels(volumes:Vector.<int>) : void
        {
            _effectStream.setAllStreamSendLevels(volumes);
        }

        
        /** connect to another chain */
        public function connectTo(ec:EffectChain) : void
        {
            _effectStream.connectTo(ec.streamingBuffer);
        }
        
        
        
    // factory
    //--------------------------------------------------
        static private var _freeList:Vector.<EffectChain> = new Vector.<EffectChain>();
        
        /** allocate new EffectChain */
        static public function alloc(effectList:Array) : EffectChain
        {
            if (effectList == null || effectList.length == 0) return null;
            var ec:EffectChain = _freeList.pop() || new EffectChain();
            ec.effectList = effectList;
            return ec;
        }
        
        
        /** delete this EffectChain */
        public function free() : void
        {
            effectList = [];
            _freeList.push(this);
        }
    }
}

