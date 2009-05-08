//----------------------------------------------------------------------------------------------------
// SiOPM Effect Module
//  Copyright (c) 2009 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound.effect {
    import org.si.sound.module.SiOPMModule;
    import org.si.sound.module.SiOPMStream;
    
    
    
    
    /** Effect Module. */
    public class SiEffectModule
    {
    // valiables
    //--------------------------------------------------------------------------------
        private var _module:SiOPMModule;
        private var _effectorChains:Vector.<EffectorChain>;
        private var _slotCount:int;
        private var _effectorInstances:* = {};
        
        
        
        
    // constructor
    //--------------------------------------------------------------------------------
        /** Constructor. */
        function SiEffectModule(module:SiOPMModule) 
        {
            _module = module;
            _effectorChains = new Vector.<EffectorChain>(SiOPMModule.STREAM_SIZE_MAX);
            for (var i:int=0; i<SiOPMModule.STREAM_SIZE_MAX; i++) {
                _effectorChains[i] = new EffectorChain();
            }
            _slotCount = 1;

            // initialize table
            SiEffectTable.initialize();
            
            // register default effectors
            register("ws",      SiEffectWaveShaper);
            register("eq",      SiEffectEqualiser);
            register("delay",   SiEffectStereoDelay);
            register("chorus",  SiEffectStereoChorus);
            register("autopan", SiEffectAutoPan);
            //register("comp",    SiEffectCompressor); // bugful!!
            
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
        /** @parivate [internal use] initialize all effectors. */
        public function initialize() : void
        {
            for (var slot:int=0; slot<SiOPMModule.STREAM_SIZE_MAX; slot++) clear(slot);
        }
        
        
        /** @parivate [internal use] prepare for processing. */
        public function prepareProcess() : void
        {
            var i:int, slot:int, ec:EffectorChain;
            
            // preparetion for all effectors
            _slotCount = 1;
            for (slot=0; slot<SiOPMModule.STREAM_SIZE_MAX; slot++) {
                ec = _effectorChains[slot];
                ec.requestChannels = 0;
                if (ec.isActive) {
                    _slotCount = slot+1;
                    ec.requestChannels = ec.chain[0].prepareProcess();
                    for (i=1; i<ec.chain.length; i++) ec.chain[i].prepareProcess();
                }
            }
            
            // set modules number of streams and channels
            _module.streamCount = _slotCount;
            for (slot=1; slot<_slotCount; slot++) {
                if (_effectorChains[slot].requestChannels > 0)
                    _module.streamBuffer[slot].channels = _effectorChains[slot].requestChannels;
            }
        }
        
        
        /** @parivate [internal use] processing. */
        public function process() : void
        {
            var i:int, slot:int, channels:int, buffer:Vector.<Number>, e:SiEffectBase, 
                bufferLength:int = _module.bufferLength,
                output:Vector.<Number> = _module.output,
                imax:int = output.length;
            // effect
            for (slot=1; slot<_slotCount; slot++) {
                channels = _module.streamBuffer[slot].channels;
                buffer   = _module.streamBuffer[slot].buffer;
                for each (e in _effectorChains[slot].chain) channels = e.process(channels, buffer, 0, bufferLength);
                for (i=0; i<imax; i++) output[i] += buffer[i];
            }
            // master effect
            for each (e in _effectorChains[0].chain) channels = e.process(channels, output, 0, bufferLength);
        }
        
        
        
        
    // effector instance manager
    //--------------------------------------------------------------------------------
        /** Register effector class
         *  @param name Effector name.
         *  @param cls SiEffectBase based class.
         */
        public function register(name:String, cls:Class) : void
        {
            _effectorInstances[name] = new EffectorInstances(cls);
        }
        
        
        /** Get effector instance by name 
         *  @param name Effector name.
         */
        public function getInstance(name:String) : SiEffectBase
        {
            if (!(name in _effectorInstances)) return null;
            var e:SiEffectBase = _effectorInstances[name].getInstance();
            e._isFree = false;
            e.initialize();
            return e;
        }
        
        
        
        
    // effector connection
    //--------------------------------------------------------------------------------
        /** Clear effector slot. 
         *  @param slot Effector slot number.
         */
        public function clear(slot:int) : void
        {
            for each (var e:SiEffectBase in _effectorChains[slot].chain) e._isFree = true;
            _effectorChains[slot].chain.length = 0;
        }
        
        
        /** Connect effector to the slot.
         *  @param slot Effector slot number.
         *  @param effector Effector instance.
         */
        public function connect(slot:int, effector:SiEffectBase) : void
        {
            _effectorChains[slot].chain.push(effector);
        }
        
        
        /** Parse MML for effector 
         *  @param slot Effector slot number.
         *  @param mml MML string.
         */
        public function parseMML(slot:int, mml:String) : void
        {
            var res:*, rex:RegExp = /([a-zA-Z_]+|,)\s*([.\-\d]+)?/g, i:int,
                cmd:String = "", argc:int = 0, args:Vector.<Number> = new Vector.<Number>(16, true);
            
            // clear
            clear(slot);
            _clearArgs();
            
            // parse mml
            res = rex.exec(mml);
            while (res) {
                if (res[1] == ",") {
                    args[argc++] = Number(res[2]);
                } else {
                    _connectEffect();
                    cmd = res[1];
                    _clearArgs();
                    args[0] = Number(res[2]);
                    argc = 1;
                }
                res = rex.exec(mml);
            }
            _connectEffect();
            
            // connect new effector
            function _connectEffect() : void {
                if (argc == 0) return;
                var e:SiEffectBase = getInstance(cmd);
                if (e) {
                    e.mmlCallback(args);
                    connect(slot, e);
                }
            }
            
            function _clearArgs() : void {
                for (var i:int=0; i<16; i++) args[i]=Number.NaN;
            }
        }
    }
}




import org.si.sound.effect.SiEffectBase;
// effector chain
class EffectorChain
{
    public var requestChannels:int = 0;
    public var chain:Vector.<SiEffectBase> = new Vector.<SiEffectBase>();
	public function get isActive() : Boolean { return (chain.length > 0); }
    function EffectorChain() {}
}


// effector instance manager
class EffectorInstances
{
    public var _instances:Array = [];
    public var _classInstance:Class;
    
    function EffectorInstances(cls:Class)
    {
        _classInstance = cls;
    }
    
    public function getInstance() : SiEffectBase
    {
        var e:SiEffectBase;
        for each (e in _instances) if (e._isFree) return e;
        e = new _classInstance();
        _instances.push(e);
        return e;
    }
}


