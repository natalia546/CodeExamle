using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Runtime.InteropServices;

using System.Runtime.InteropServices.ComTypes;

namespace Передача_структуры_в_dll
{

    class Program
    {
        [DllImport(@"StructDll.dll")]
        static  extern void withStruct(Input[] cpuInArray, Output[] cpuOutArray, int arraySize);
        [DllImport(@"StructDll.dll")]
        static extern void withClass(A[] a,int arraySize);
        [DllImport(@"StructDll.dll")]
        static extern void withStructList(List<Input> cpuInArray, List<Output> cpuOutArray, int arraySize);
        public struct Output
        {
            public double x, y;

        }
        public struct Input
        {
            public double a, k;

        }
        public class B
        {
            public double l;
        }
        public class A
        {
            public double r;
            public B[] k=new B[10];
            public A() { }
        }
        static void Main(string[] args)
        {
            int arraySize = 512 * 5;
            List<Input> cpuInList = new List<Input>();
            List<Output> cpuOutList = new List<Output>();
            Random rand = new Random();
            A[] a = new A[arraySize];
            for (int i = 0; i < arraySize; i++)
            {
                a[i] = new A();
                a[i].r= rand.NextDouble() * 10 - 5;
                for(int j=0;j<10;j++)
                a[i].k[j] = new B() { l = rand.NextDouble() * 10 - 5 };
                Input inp= new Input();
           inp.a = rand.NextDouble() * 10 - 5;
                inp.k = rand.NextDouble() * 10 - 5;
                Output outp = new Output();
                outp.y = 0;
                outp.x = 0;
                cpuInList.Add(inp);
                cpuOutList.Add(outp);
            }
           // var s = Marshal.SizeOf(typeof(Input));
            Console.WriteLine("Input a= {0}, k = {1}", cpuInList[6].a, cpuInList[6].k);
        
            withStructList(cpuInList, cpuOutList, arraySize);
           // withStruct(cpuInArray, cpuOutArray, arraySize);
            var s1= Marshal.SizeOf(typeof(A));
            Console.WriteLine("A = "+s1);
            withClass(a, arraySize);
            Console.Read();
        }
    }
}
