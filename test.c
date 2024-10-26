#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <limits.h>
#include <linux/limits.h>

#define MAX_HEADER_SIZE 512

typedef struct PixelNode {
    unsigned char Red;
    unsigned char Green;
    unsigned char Blue;
    unsigned char CdfValue;
    struct PixelNode* up;
    struct PixelNode* down;
    struct PixelNode* left;
    struct PixelNode* right;
} PixelNode;

//extern PixelNode* readPPM(const char* filename); 
/*extern void computeCDFValues(PixelNode* head);
extern void applyHistogramEqualization(PixelNode* head);
extern void writePPM(const char* filename, const PixelNode* head);
*/
extern fopen, fread, fscanf, fclose;

void writeRGB(PixelNode* head) {
    if (head == NULL)
        return;

    while(head != NULL) {
        PixelNode* curr = head;
        while(curr != NULL) {
            printf(curr->Red);
            printf(curr->Green);
            printf(curr->Blue);
            printf(" ");
            curr = curr->right;
        }
        printf("\n");
        head = head->down;
    }
}
void writeCDF(PixelNode* head) {
    if (head == NULL)
        return;

    while(head != NULL) {
        PixelNode* curr = head;
        while(curr != NULL) {
            printf(curr->CdfValue);
            printf(" ");
            curr = curr->right;
        }
        printf("\n");
        head = head->down;
    }
}
PixelNode* readFile() {

}
int main() {
    const char* inputFilename = "image01.ppm";
    const char* outputFilename = "output.ppm";

    PixelNode* head = readPPM(inputFilename);
    if (head == NULL) {
        fprintf(stderr, "Failed to read the image.\n");
        return 1;
    }
    writeRGB(head); // output for testing
    writeCDF(head);
    /*computeCDFValues(head);
    writeCDF(head); // output for testing

    applyHistogramEqualization(head);
    writeCDF(head); // output for testing

    writePPM(outputFilename, head);*/

    return 0;
}