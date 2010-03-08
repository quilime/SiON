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
        /** @private [internal] activate local effect */
        internal function _activateLocalEffect() : void
        {
            var driver:SiONDriver = SiONDriver.mutex;
            if (driver) {
                _effectStream = driver.effector.newLocalEffect();
                if (_effectStream) {
                    _effectStream.chain = Vector.<SiEffectBase>(_effectList);
                }
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
        
        
        /** @private [internal] compare chain list */
        internal function _isEqualWith(list:Array) : Boolean
        {
            if (_effectList.length != list.length) return false;
            var i:int, imax:int = list.length;
            for (i=0; i<imax; i++) {
                if (_effectList[i] !== list[i]) return false;
            }
            return true;
        }
        
        
        public function setAllStreamSendLevels(volumes:Vector.<int>) : void
        {
            _effectStream.setAllStreamSendLevels(volumes);
        }

        
        
        
    // factory
    //--------------------------------------------------
        static private var _freeList:Vector.<EffectChain> = new Vector.<EffectChain>();
        static private var _activeList:Vector.<EffectChain> = new Vector.<EffectChain>();
        
        
        static public function alloc(effectList:Array) : EffectChain
        {
            if (effectList == null || effectList.length == 0) return null;
            var ec:EffectChain;
            for each (ec in _activeList) {
                if (ec._isEqualWith(effectList)) return ec;
            }
            ec = _freeList.pop() || new EffectChain();
            ec.effectList = effectList;
            _activeList.push(ec);
            return ec;
        }
        
        
        public function free() : void
        {
            effectList = [];
            var i:int = _activeList.indexOf(this);
            if (i != -1) _activeList.splice(i, 1);
            _freeList.push(this);
        }
    }
}

