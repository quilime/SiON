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
        static public const STREAM_SIZE_MAX:int = 8;
        static public const PIPE_SIZE:int = 5;
        
        
        
        
    // valiables
    //--------------------------------------------------
        /** Intial values for operator parameters */
        public var initOperatorParam:SiOPMOperatorParam;
        /** zero buffer */
        public var zeroBuffer:SLLint;
        /** stereo output buffer */
        public var streamBuffer:Vector.<SiOPMStream>;
        
        /** Operator */
        protected var _freeOperators:Vector.<SiOPMOperator>;
        /** buffer length */
        protected var _bufferLength:int;
        
        // pipes
        private var _pipeBuffer:Vector.<SLLint>;
        private var _pipeBufferPager:Vector.<Vector.<SLLint>>;
        
        
    // properties
    //--------------------------------------------------
        /** Buffer count */
        public function get output() : Vector.<Number> { return streamBuffer[0].buffer; }
        /** Buffer length */
        public function get bufferLength() : int { return _bufferLength; }
        
        
        /** stream count */
        public function set streamCount(count:int) : void 
        {
            var i:int;
            
            // allocate streams
            if (count > STREAM_SIZE_MAX) count = STREAM_SIZE_MAX;
            if (streamBuffer.length != count) {
                if (streamBuffer.length < count) {
                    i = streamBuffer.length;
                    streamBuffer.length = count;
                    for (; i<count; i++) streamBuffer[i] = SiOPMStream.newStream(2, _bufferLength);
                } else {
                    for (i=count; i<streamBuffer.length; i++) SiOPMStream.deleteStream(streamBuffer[i]);
                    streamBuffer.length = count;
                }
            }
        }
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** Default constructor
         *  @param busSize Number of mixing buses.
         */
        function SiOPMModule()
        {
            // initialize table once
            SiOPMTable.initialize(3580000, 44100);
            
            // initial values
            initOperatorParam = new SiOPMOperatorParam();
            
            // stream buffer
            streamBuffer = new Vector.<SiOPMStream>();
            streamCount = 1;

            // zero buffer gives always 0
            zeroBuffer = SLLint.allocRing(1);
            
            // others
            _bufferLength = 0;
            _pipeBuffer = new Vector.<SLLint>(PIPE_SIZE, true);
            _pipeBufferPager = new Vector.<Vector.<SLLint>>(PIPE_SIZE, true);
            _freeOperators = new Vector.<SiOPMOperator>();
            
            // call at once
            SiOPMChannelManager.initialize(this, true);
        }
        
        
        
        
    // operation
    //--------------------------------------------------
        /** Initialize module and all tone generators.
         *  @param channelCount ChannelCount
         *  @param bufferLength Maximum buffer size processing at once.
         */
        public function initialize(channelCount:int, bufferLength:int) : void
        {
            var i:int, stream:SiOPMStream, bufferLength2:int = bufferLength<<1;

            // allocate buffer
            if (_bufferLength != bufferLength) {
                _bufferLength = bufferLength;
                for each (stream in streamBuffer) {
                    stream.buffer.length = bufferLength2;
                }
                for (i=0; i<PIPE_SIZE; i++) {
                    SLLint.freeRing(_pipeBuffer[i]);
                    _pipeBuffer[i] = SLLint.allocRing(bufferLength);
                    _pipeBufferPager[i] = SLLint.createRingPager(_pipeBuffer[i], true);
                }
            }

            // set standard outputs channel count
            streamBuffer[0].channels = channelCount;
            
            // initialize all channels
            SiOPMChannelManager.initializeAllChannels();
        }
        
        
        /** Reset. */
        public function reset() : void
        {
            // reset all channels
            SiOPMChannelManager.resetAllChannels();
        }
        
        /** Clear all buffer. */
        public function clearAllBuffers() : void
        {
            var idx:int, i:int, imax:int, buf:Vector.<Number>, stream:SiOPMStream;
            for each (stream in streamBuffer) {
                buf = stream.buffer;
                imax = buf.length;
                for (i=0; i<imax; i++) buf[i] = 0;
            }
        }
        
        
        /** get pipe buffer */
        public function getPipe(pipeNum:int, index:int=0) : SLLint
        {
            return _pipeBufferPager[pipeNum][index];
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

