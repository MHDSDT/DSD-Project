import random


def testGenerator(N):
    f = open("testA.txt", 'w')
    f1 = open("testB.txt", 'w')
    for i in range(N):
        for j in range(32):
            f.write(str(random.randint(0, 1)))
            f1.write(str(random.randint(0, 1)))
        f.write("\n")
        f1.write("\n")
    f.close()


if __name__ == '__main__':
    testGenerator(4)

