//----------------------------------------------------------------------------------------------------
// SiON Effect Module
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.effector {
    import org.si.sion.module.SiOPMModule;
    import org.si.sion.module.SiOPMStream;
    import org.si.sion.namespaces._sion_internal;
    
    
    /** Effect Module. */
    public class SiEffectModule
    {
    // constant
    //--------------------------------------------------------------------------------
        
        
        
    // valiables
    //--------------------------------------------------------------------------------
        private var _module:SiOPMModule;
        private var _freeEffects:Vector.<SiEffectStream>;
        private var _localEffects:Vector.<SiEffectStream>;
        private var _globalEffects:Vector.<SiEffectStream>;
        private var _masterEffect:SiEffectStream;
        private var _globalEffectCount:int;
        static private var _effectorInstances:* = {};
        
        
        
        
    // constructor
    //--------------------------------------------------------------------------------
        /** Constructor. */
        function SiEffectModule(module:SiOPMModule) 
        {
            _module = module;
            _freeEffects   = new Vector.<SiEffectStream>();
            _localEffects  = new Vector.<SiEffectStream>();
            _globalEffects = new Vector.<SiEffectStream>(SiOPMModule.STREAM_SEND_SIZE, true);
            _masterEffect  = new SiEffectStream(_module, _module.outputStream);

            // initialize table
            SiEffectTable.initialize();
            
            // register default effectors
            register("ws",      SiEffectWaveShaper);
            register("eq",      SiEffectEqualiser);
            register("delay",   SiEffectStereoDelay);
            register("reverb",  SiEffectStereoReverb);
            register("chorus",  SiEffectStereoChorus);
            register("autopan", SiEffectAutoPan);
            register("ds",      SiEffectDownSampler);
            register("speaker", SiEffectSpeakerSimulator);
            register("comp",    SiEffectCompressor);
            
            register("lf", SiFilterLowPass);
            register("hf", SiFilterHighPass);
            register("bf", SiFilterBandPass);
            register("nf", SiFilterNotch);
            register("pf", SiFilterPeak);
            register("af", SiFilterAllPass);
            
            register("nlf", SiCtrlFilterLowPass);
            register("nhf", SiCtrlFilterHighPass);
        }
        
        
        
        
    // operations
    //--------------------------------------------------------------------------------
        /** Initialize all effectors. This function is called from SiONDriver.play() with the 2nd argment true. 
        *  When you want to connect effectors by code, you have to call this first, then call connect() and SiONDriver.play() with the 2nd argment false.
         */
        public function initialize() : void
        {
            var effect:SiEffectStream, i:int;
            for each (effect in _localEffects) _freeEffects.push(effect);
            _localEffects.length = 0;
            _globalEffects[0] = _masterEffect;
            for (i=1; i<SiOPMModule.STREAM_SEND_SIZE; i++) _globalEffects[i] = null;
            _globalEffectCount = 0;
        }
        
        
        public function reset() : void
        {
        }
        
        
        /** @private [sion internal] prepare for processing. */
        _sion_internal function _prepareProcess() : void
        {
            var slot:int, channelCount:int;
            
            // local effect
            for (slot=0; slot<_localEffects.length; slot++) {
                _localEffects[slot].prepareProcess();
            }
            
            // global effect (slot1-slot7)
            _globalEffectCount = 0;
            for (slot=1; slot<SiOPMModule.STREAM_SEND_SIZE; slot++) {
                _module.streamSlot[slot] = null; // reset module's stream slot
                if (_globalEffects[slot]) {
                    channelCount = _globalEffects[slot].prepareProcess();
                    if (channelCount > 0) {
                        _module.streamSlot[slot] = _globalEffects[slot]._stream;
                        _globalEffectCount++;
                    }
                }
            }
            
            // master effect (slot0)
            _masterEffect.prepareProcess();
        }
        
        
        /** @private [sion internal] Clear output buffer. */
        _sion_internal function _beginProcess() : void
        {
            var slot:int;
            
            // local effect
            for (slot=0; slot<_localEffects.length; slot++) {
                _localEffects[slot]._stream.clear();
            }
            
            // global effect (slot1-slot7)
            for (slot=1; slot<SiOPMModule.STREAM_SEND_SIZE; slot++) {
                if (_globalEffects[slot]) _globalEffects[slot]._stream.clear();
            }
            
            // do nothing on master effect
        }
        
        
        /** @private [sion internal] processing. */
        _sion_internal function _endProcess() : void
        {
            var i:int, slot:int, buffer:Vector.<Number>,
                bufferLength:int = _module.bufferLength,
                output:Vector.<Number> = _module.output,
                imax:int = output.length;
            
            // local effect
            for (slot=0; slot<_localEffects.length; slot++) {
                _localEffects[slot].process(0, bufferLength);
            }
            
            // global effect (slot1-slot7)
            for (slot=1; slot<SiOPMModule.STREAM_SEND_SIZE; slot++) {
                if (_globalEffects[slot]) {
                    _globalEffects[slot].process(0, bufferLength, false);
                    for (i=0; i<imax; i++) output[i] += buffer[i];
                }
            }
            
            // master effect (slot0)
            _masterEffect.process(0, bufferLength, false);
        }
        
        
        
        
    // effector instance manager
    //--------------------------------------------------------------------------------
        /** Register effector class
         *  @param name Effector name.
         *  @param cls SiEffectBase based class.
         */
        static public function register(name:String, cls:Class) : void
        {
            _effectorInstances[name] = new EffectorInstances(cls);
        }
        
        
        /** Get effector instance by name 
         *  @param name Effector name in mml.
         */
        static public function getInstance(name:String) : SiEffectBase
        {
            if (!(name in _effectorInstances)) return null;
            
            var effect:SiEffectBase, 
                factory:EffectorInstances = _effectorInstances[name];
            for each (effect in factory._instances) {
                if (effect._isFree) {
                    effect._isFree = false;
                    effect.initialize();
                    return effect;
                }
            }
            effect = new factory._classInstance();
            factory._instances.push(effect);
            
            effect._isFree = false;
            effect.initialize();
            return effect;
        }
        
        
        
        
    // effector connection
    //--------------------------------------------------------------------------------
        /** Clear effector slot. 
         *  @param slot Effector slot number.
         */
        public function clear(slot:int) : void
        {
            if (slot == 0) {
                _masterEffect.initialize();
            } else {
                if (_globalEffects[slot] != null) _freeEffects.push(_globalEffects[slot]);
                _globalEffects[slot] = null;
            }
        }
        
        
        /** Connect effector to the slot.
         *  @param slot Effector slot number.
         *  @param effector Effector instance.
         */
        public function connect(slot:int, effector:SiEffectBase) : void
        {
            if (_globalEffects[slot] == null) _globalEffects[slot] = _allocStream();
            _globalEffects[slot].connect(effector);
        }
        
        
        /** Parse MML for effector 
         *  @param slot Effector slot number.
         *  @param mml MML string.
         *  @param postfix Postfix string.
         */
        public function parseMML(slot:int, mml:String, postfix:String) : void
        {
            if (_globalEffects[slot] == null) _globalEffects[slot] = _allocStream();
            _globalEffects[slot].parseMML(mml, postfix);
        }
        

        /** Get connected effector
         *  @param slot Effector slot number.
         *  @param index The index of connected effector.
         *  @return Effector instance.
         */
        public function getEffector(slot:int, index:int) : SiEffectBase 
        {
            if (_globalEffects[slot] == null) return null;
            return _globalEffects[slot].getEffector(index);
        }
        
        
        /** Create new local effector connector */
        public function newLocalEffect() : SiEffectStream
        {
            var inst:SiEffectStream = _allocStream();
            _localEffects.push(inst);
            return inst;
        }
        
        
        /** Delete local effector connector */
        public function deleteLocalEffect(inst:SiEffectStream) : void
        {
            var i:int = _localEffects.indexOf(inst);
            if (i != -1) _localEffects.splice(i, 0);
            _freeEffects.push(inst);
        }
        
        
        
        
    // functory
    //--------------------------------------------------------------------------------
        private function _allocStream() : SiEffectStream
        {
            var inst:SiEffectStream = _freeEffects.pop() || new SiEffectStream(_module);
            inst.initialize();
            return inst;
        }
    }
}




import org.si.sion.effector.SiEffectBase;
// effector instance manager
class EffectorInstances
{
    public var _instances:Array = [];
    public var _classInstance:Class;
    
    function EffectorInstances(cls:Class)
    {
        _classInstance = cls;
    }
}


