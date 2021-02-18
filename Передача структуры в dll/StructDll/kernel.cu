
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <cmath>
#include <ctime>
#include <iostream>
#include <chrono>
#include <limits>
#define pointsCount 8
#define n 13


typedef struct
{
	double a, k;
} Input;

typedef struct
{
	double y, x;
} Output;

extern "C" __declspec(dllexport) void   withStruct(Input cpuInArray[], Output cpuOutArray[], int arraySize);
__global__ void sampleStructFunction(Output* op, Input* ip, int size)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;

	if (idx < size) {
		double x0;
		double minc;
		double minx = 0;
		double maxx = 1;
		double besty = 0;
		float bestx = 0;

		double step;
		double minx0;
		for (int j = 1; j <= n; j++)
		{
			step = (maxx - minx) / pointsCount;
			x0 = (double)(step + minx) / 2;
			minc = ip[idx].a * x0 * x0 * x0 + ip[idx].k;
			minx0 = x0;

			for (int i = 1; i < pointsCount; i++)
			{
				x0 = (double)(i + 1) * step + minx;
				double m = ip[idx].a * x0 * x0 * x0 + ip[idx].k;
				if (fabsf(minc) > fabsf(m))
				{
					minc = m;
					minx0 = x0;
				}
			}

			minx = minx0 - step; maxx = minx0 + step;


			besty = minc;
			bestx = minx0;

		}
		op[idx].y = besty;
		op[idx].x = bestx;
	}
}


int main()
{
/*	int arraySize = 512 * 50000;
	int InSize = sizeof(Input);
	int numBytesIn = arraySize * InSize;
	Input* cpuInArray;
	cudaMalloc((void**)& cpuInArray, numBytesIn);


	int OutSize = sizeof(Output);
	int numBytesOut = arraySize * OutSize;
	Output* cpuOutArray;
	cudaMalloc((void**)& cpuOutArray, numBytesOut);
	srand(time(0));
	for (int i = 0; i < arraySize; i++)
	{
		cpuInArray[i].a = rand() % 10 + rand() / double(RAND_MAX) - 5;
		cpuInArray[i].k = rand() % 10 + rand() / double(RAND_MAX) - 5;
		cpuOutArray[i].y = 0;
		cpuOutArray[i].x = 0;
	}

	 withStruct(cpuInArray, cpuOutArray, arraySize);*/
	
    return 0;
}

// Helper function for using CUDA to add vectors in parallel.
extern "C" __declspec(dllexport) void withStruct(Input cpuInArray[], Output cpuOutArray[], int arraySize)
{
	float timerValueGPU, timerValueCPU;
	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);
	
	int InSize = sizeof(Input);
	int numBytesIn = arraySize * InSize;
	Input * gpuIntArray;
	cudaMalloc((void**)& gpuIntArray, numBytesIn);


	int OutSize = sizeof(Output);
	int numBytesOut = arraySize * OutSize;
	Output* gpuOutArray;
	cudaMalloc((void**)& gpuOutArray, numBytesOut);

	cudaError_t cudaStatus;
	int N_thread = 512; // число нитей в блоке
	int N_blocks = (int)arraySize / N_thread;
	if ((arraySize % N_thread) == 0)
	{
		N_blocks = arraySize / N_thread;
	}
	else
	{
		N_blocks = (int)(arraySize / N_thread) + 1;
	}
	dim3 blocks(N_blocks);

	// Choose which GPU to run on, change this on a multi-GPU system.
	cudaStatus = cudaSetDevice(0);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
		goto Error;
	}
	cudaEventRecord(start, 0);
	// Copy input vectors from host memory to GPU buffers.
	cudaStatus = cudaMemcpy(gpuIntArray, cpuInArray, arraySize * sizeof(Input), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

	// Launch a kernel on the GPU with one thread for each element.

	printf("begin\r\n");
	sampleStructFunction << <N_blocks, N_thread >> > (gpuOutArray, gpuIntArray, arraySize);
	printf("the end sampleFunction\r\n");
	cudaStatus = cudaGetLastError();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
		goto Error;
	}

	// cudaDeviceSynchronize waits for the kernel to finish, and returns
	// any errors encountered during the launch.
	cudaStatus = cudaDeviceSynchronize();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
		goto Error;
	}

	// Copy output vector from GPU buffer to host memory.
	cudaStatus = cudaMemcpy(cpuOutArray, gpuOutArray, arraySize * sizeof(Output), cudaMemcpyDeviceToHost);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}
	cudaEventRecord(stop, 0);
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&timerValueGPU, start, stop);
	printf("\n GPU calculation time: %f ms\n", timerValueGPU);
Error:
	cudaFree(gpuIntArray);
	cudaFree(gpuOutArray);
}
