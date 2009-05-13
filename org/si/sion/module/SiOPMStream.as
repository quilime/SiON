//----------------------------------------------------------------------------------------------------
// Stream buffer class
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------

package org.si.sion.module {
    import org.si.utils.SLLint;
    
    
    public class SiOPMStream {
        // valiables
        //--------------------------------------------------
        /** number of channels */
        public var channels:int = 2;
        /** stream buffer */
        public var buffer:Vector.<Number> = new Vector.<Number>();

        /** coefficient of volume/panning */
        protected var _panTable:Vector.<Number>;
        protected var _i2n:Number;

        
        
        
        // constructor
        //--------------------------------------------------
        function SiOPMStream()
        {
            _panTable = SiOPMTable.instance.panTable;
            _i2n = SiOPMTable.instance.i2n;
        }
        
        
        
        
        // operation
        //--------------------------------------------------
        public function write(pointer:SLLint, start:int, len:int, vol:Number, pan:int) : void 
        {
            var i:int, n:Number, imax:int = (start + len)<<1;
            vol *= _i2n;
            if (channels == 2) {
                // stereo
                var volL:Number = _panTable[128-pan] * vol,
                    volR:Number = _panTable[pan] * vol;
                for (i=start<<1; i<imax;) {
                    n = Number(pointer.i);
                    buffer[i] += n * volL;  i++;
                    buffer[i] += n * volR;  i++;
                    pointer = pointer.next;
                }
            } else 
            if (channels == 1) {
                // monoral
                for (i=start<<1; i<imax;) {
                    n = Number(pointer.i) * vol;
                    buffer[i] += n; i++;
                    buffer[i] += n; i++;
                    pointer = pointer.next;
                }
            }
        }
        
        
        public function writeVectorInt(pointer:Vector.<int>, startPointer:int, startBuffer:int, len:int, vol:Number, pan:int, sampleChannelCount:int) : void
        {
            var i:int, j:int, n:Number, jmax:int = startPointer + len, volL:Number, volR:Number;
            vol *= 0.000030517578125; // 1/32768
            if (channels == 2) {
                if (sampleChannelCount == 2) {
                    // stereo data to stereo buffer
                    for (j=startPointer, i=startBuffer<<1; j<jmax; j++) {
                        volL = Number((pointer[j]&65535)-32768) * vol;
                        volR = Number((pointer[j]>>>16) -32768) * vol;
                        buffer[i] += volL;  i++;
                        buffer[i] += volR;  i++;
                    }
                } else {
                    // monoral data to stereo buffer
                    volL = _panTable[128-pan] * vol;
                    volR = _panTable[pan]     * vol;
                    for (j=startPointer, i=startBuffer<<1; j<jmax; j++) {
                        n = Number(pointer[j]);
                        buffer[i] += n * volL;  i++;
                        buffer[i] += n * volR;  i++;
                    }
                }
            } else 
            if (channels == 1) {
                // monoral
                for (j=startPointer, i=startBuffer<<1; j<jmax; j++) {
                    n = Number(pointer[j]) * vol;
                    buffer[i] += n; i++;
                    buffer[i] += n; i++;
                }
            }
        }
        
        
        
        
        // factory
        //--------------------------------------------------
        static private var freeBuffers:Vector.<SiOPMStream> = new Vector.<SiOPMStream>();
        
        
        /** create new stream buffer */
        static public function newStream(channels:int, bufferLength:int) : SiOPMStream
        {
            bufferLength <<= 1;
            var stream:SiOPMStream = freeBuffers.pop() || new SiOPMStream();
            stream.channels = channels;
            stream.buffer.length = bufferLength;
            return stream;
        }
        
        
        /** delete stream buffer */
        static public function deleteStream(stream:SiOPMStream) : void
        {
            freeBuffers.push(stream);
        }
    }
}

