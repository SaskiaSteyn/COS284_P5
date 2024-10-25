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

// Function prototypes
extern void computeCDFValues(PixelNode* head);
//extern void applyHistogramEqualization(PixelNode* head);
//extern void writePPM(const char* filename, const PixelNode* head);

// Function to create a new PixelNode
PixelNode* createPixelNode(unsigned char red, unsigned char green, unsigned char blue) {
    PixelNode* node = (PixelNode*)malloc(sizeof(PixelNode));
    node->Red = red;
    node->Green = green;
    node->Blue = blue;
    node->CdfValue = 0; // Initialize CdfValue to 0
    node->up = NULL;
    node->down = NULL;
    node->left = NULL;
    node->right = NULL;
    return node;
}

// Function to link nodes together in a 2D grid
void linkNodes(PixelNode*** grid, int rows, int cols) {
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            if (i > 0) {
                grid[i][j]->up = grid[i - 1][j]; // link up
                grid[i - 1][j]->down = grid[i][j]; // link down
            }
            if (j > 0) {
                grid[i][j]->left = grid[i][j - 1]; // link left
                grid[i][j - 1]->right = grid[i][j]; // link right
            }
        }
    }
}

int main() {
    // Create a 3x3 grid of PixelNodes
    int rows = 3;
    int cols = 3;
    PixelNode*** grid = (PixelNode***)malloc(rows * sizeof(PixelNode**));

    // Allocate the grid and create pixel nodes with RGB values
    for (int i = 0; i < rows; i++) {
        grid[i] = (PixelNode**)malloc(cols * sizeof(PixelNode*));
        for (int j = 0; j < cols; j++) {
            unsigned char red = (i + j) * 30;   // Example red value
            unsigned char green = (i + j) * 20; // Example green value
            unsigned char blue = (i + j) * 10;  // Example blue value
            grid[i][j] = createPixelNode(red, green, blue);
        }
    }

    // Link the nodes in the grid
    linkNodes(grid, rows, cols);

    // Set head pointer to the top-left corner of the grid
    PixelNode* head = grid[0][0];

    // Compute CDF values and apply histogram equalization
    computeCDFValues(head);
    // applyHistogramEqualization(head); // Uncomment if implemented

    // Optionally write output to a file (uncomment if implemented)
    // writePPM("output.ppm", head);

    // Free allocated memory
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            free(grid[i][j]);
        }
        free(grid[i]);
    }
    free(grid);

    return 0;
}
