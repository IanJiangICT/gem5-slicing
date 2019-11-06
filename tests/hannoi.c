/*
 * C program for Tower of Hanoi using Recursion
 */
#include <stdio.h>
 
void towers(int, char, char, char);
static unsigned long long move_cnt = 0;
 
int main()
{
    //int num = 25;
    int num = 20;
 
    towers(num, 'A', 'C', 'B');
	printf("num = %d, move_cnt = %lld\n", num, move_cnt);
    return 0;
}
void towers(int num, char frompeg, char topeg, char auxpeg)
{
    if (num == 1)
    {
		move_cnt++;
        return;
    }
    towers(num - 1, frompeg, auxpeg, topeg);
	move_cnt++;
    towers(num - 1, auxpeg, topeg, frompeg);
}
