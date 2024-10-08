#include <cstdio>
#include "cpu.h"

#include "common.h"

namespace StreamCompaction {
    namespace CPU {
        using StreamCompaction::Common::PerformanceTimer;
        PerformanceTimer& timer()
        {
            static PerformanceTimer timer;
            return timer;
        }

        /**
         * CPU scan (prefix sum).
         * For performance analysis, this is supposed to be a simple for loop.
         * (Optional) For better understanding before starting moving to GPU, you can simulate your GPU scan in this function first.
         */
        void scan(int n, int *odata, const int *idata) {
            timer().startCpuTimer();
            odata[0] = 0;
            for (int i = 1; i < n; ++i) {
                odata[i] = odata[i - 1] + idata[i - 1];
            }
            timer().endCpuTimer();
        }

        /**
         * CPU stream compaction without using the scan function.
         *
         * @returns the number of elements remaining after compaction.
         */
        int compactWithoutScan(int n, int *odata, const int *idata) {
            timer().startCpuTimer();
            int count = 0;
            for (int i = 0; i < n; ++i) {
                if (idata[i] > 0) {
                    odata[count] = idata[i];
                    count++;
                }
            }
            timer().endCpuTimer();
            return count;
        }

        /**
         * CPU stream compaction using scan and scatter, like the parallel version.
         *
         * @returns the number of elements remaining after compaction.
         */
        int compactWithScan(int n, int *odata, const int *idata) {
            timer().startCpuTimer();
            // Array that meets criteria, 1: meet   2: doesn't meet
            int* CriteriaArr = new int[n * sizeof(int)];
            for (int i = 0; i < n; ++i) {
                if (idata[i] > 0) {
                    CriteriaArr[i] = 1;
                } 
                else {
                    CriteriaArr[i] = 0;
                }
            }
            // run exclusive scan
            odata[0] = 0;
            for (int i = 1; i < n; ++i) {
                odata[i] = odata[i - 1] + CriteriaArr[i - 1];
            }
            int size = odata[n-1];
            // scatter
            int count = 0;
            for (int i = 0; i < n; ++i) {
                if (CriteriaArr[i] > 0) {
                    odata[count] = idata[i];
                    count++;
                }
            }

            timer().endCpuTimer();
            delete[] CriteriaArr;
            return size;
        }
    }
}
