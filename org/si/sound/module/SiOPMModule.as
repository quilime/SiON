//----------------------------------------------------------------------------------------------------
// FM sound module based on OPM emulator and TSS algorism.
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound.module {
    import org.si.utils.SLLNumber;
    import org.si.utils.SLLint;
    import org.si.sound.effect.*;
    
    
    
    
    /** FM sound module based on OPM emulator and TSS algorism. */
    public class SiOPMModule
    {
    // constants
    //--------------------------------------------------
        static public const WAVE_BUFFER_SIZE:int = 5;
        
        
        
        
    // valiables
    //--------------------------------------------------
        /** Intial values for operator parameters */
        public var initOperatorParam:SiOPMOperatorParam;
        /** zero buffer */
        public var zeroBuffer:SLLint;
        
        /** Operator */
        protected var _freeOperators:Array;
        /** stereo output buffer */
        protected var _outputBuffer:SLLNumber;
        /** buffer length */
        protected var _bufferLength:int;
        
        // pipes
        private var _waveBuffer:Vector.<SLLint>;
        
        
        
        
    // properties
    //--------------------------------------------------
        /** Stereo output buffer. The length is bufferLength*2. */
        public function get outputBuffer() : SLLNumber
        {
            return _outputBuffer;
        }
        
        
        /** Buffer length */
        public function get bufferLength() : int
        {
            return _bufferLength;
        }

        
        
        
    // constructor
    //--------------------------------------------------
        /** Default constructor */
        function SiOPMModule()
        {
            // initial values
            initOperatorParam = new SiOPMOperatorParam();
            
            // TG managers (expandable)
            _freeOperators = [];

            // zero buffer gives always 0
            zeroBuffer = SLLint.allocRing(1);
            
            // others
            _bufferLength = 0;
            _outputBuffer = null;
            _waveBuffer = new Vector.<SLLint>(WAVE_BUFFER_SIZE, true);
            for (var i:int=0; i<WAVE_BUFFER_SIZE; i++) { _waveBuffer[i] = null; }
            
            // call at once
            SiOPMChannelManager.initialize(this, true);
        }
        
        
        
        
    // operation
    //--------------------------------------------------
        /** Initialize module and all tone generators.
         *  @param bufferLength Maximum buffer size processing at once.
         */
        public function initialize(bufferLength:int) : void
        {
            var i:int, imax:int;

            // allocate buffer
            if (_bufferLength != bufferLength) {
                _bufferLength = bufferLength;
                SLLNumber.freeRing(_outputBuffer);
                _outputBuffer = SLLNumber.allocRing(bufferLength*2);
                for (i=0; i<WAVE_BUFFER_SIZE; i++) {
                    SLLint.freeRing(_waveBuffer[i]);
                    _waveBuffer[i] = SLLint.allocRing(bufferLength);
                }
            }

            // initialize all channels
            SiOPMChannelManager.initializeAllChannels();
        }
        
        
        /** Reset. */
        public function reset() : void
        {
            // reset all channels
            SiOPMChannelManager.resetAllChannels();
        }
        
        
        /** get pipe buffer */
        public function getPipe(index:int) : SLLint
        {
            return _waveBuffer[index];
        }
        
        
        /** @private [internal use] Alloc operator instance WITHOUT initializing. Call from SiOPMChannelFM. */
        internal function allocOperator() : SiOPMOperator
        {
            return _freeOperators.pop() || new SiOPMOperator(this);
        }

        
        /** @private [internal use] Free operator instance. Call from SiOPMChannelFM. */
        internal function freeOperator(osc:SiOPMOperator) : void
        {
            _freeOperators.push(osc);
        }
    }
}

