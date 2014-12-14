/***************************************************************************\
|*+-----------------------------------------------------------------------+*|
|*|                                                                       |*|
|*|  helpers.c:  Helper functions for tetris.rc                           |*|
|*|              CSE 131 :: Compiler Construction                         |*|
|*|                                                                       |*|
|*|  Author:     Garo Bournoutian, Winter 2012                            |*|
|*|              (based heavily on Tetris for Terminals, by Mike Taylor)  |*|
|*|                                                                       |*|
|*|  Usage:      gcc helpers.c -c -o helpers.o                            |*|             
|*|              ./RC tetric.rc                                           |*|             
|*|              make compile LINKOBJ='helpers.o -lcurses'                |*|
|*|              ./a.out                                                  |*|            
|*|                                                                       |*|
|*+-----------------------------------------------------------------------+*|
\***************************************************************************/

#include <stdlib.h>
#include <string.h>
#include <curses.h>
#include <unistd.h>


/****************
* Macro Defines *
****************/
#define WALL_CHAR    '|'
#define FLOOR_CHAR   '='
#define CORNER_CHAR  '+'
#define BLANK_CHAR   ' '

#define LINELEN      160 /* Maximum length of a line of text */
#define SCORE_WIDTH  7   /* Number of digits in scores */


/*********************
* External Variables *
*********************/
extern int score;
extern int numPieces;
extern int numLevels;


/*******************
* Static Variables *
*******************/
static int gameWidth;
static int gameDepth;
static int inCurses;


//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////
////  F U N C T I O N S //////////////////////////////////
//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////

void registerDim(int depth, int width) {
    gameDepth = depth;
    gameWidth = width;
}

int getRandom(int max) {
    static int seedInitialized = 0;
    if ( !seedInitialized ) {
        srand(time(NULL));
        seedInitialized = 1;
    }
    return (rand() % max);
}

void myrefresh() {
    move(gameDepth+2, 0);
    refresh();
}

void setupCurses() {
    initscr();
    clear();
    noecho();
    crmode();
    inCurses = 1;
}

void removeCurses() {
    if ( inCurses ) {
        myrefresh();
        echo();
        crmode();
        endwin();
        inCurses = 0;
    }
}

void clearArea() {
    int i, j, fastflag = 0;
    static char buffer[LINELEN];

    for ( i = 0; i < gameDepth; ++i ) {
        move(i, 2);
        for ( j = 0; j < 2*gameWidth; ++j ) {
            addch(BLANK_CHAR);
        }

        if ( fastflag == 0 ) {
            move(i+1, 2);
            for ( j = 0; j < 2*gameWidth; ++j ) {
                addch(FLOOR_CHAR);
            }
            myrefresh();

            if ( checkKeypress(1, 50000) != 0 ) {
                fastflag = 1;
                read(0, buffer, LINELEN);
            }
        }
    }

    move(gameDepth, 2);
    for ( j = 0; j < 2*gameWidth; ++j ) {
        addch(FLOOR_CHAR);
    }

    mvaddch(gameDepth, 0, CORNER_CHAR);
    addch(CORNER_CHAR);
    mvaddch(gameDepth, 2*gameWidth+2, CORNER_CHAR);
    addch(CORNER_CHAR);

    // Clear 'Next' piece area
    mvaddstr(7,  2*gameWidth+6, "              ");
    mvaddstr(8,  2*gameWidth+6, "              ");
    mvaddstr(9,  2*gameWidth+6, "              ");
    mvaddstr(10, 2*gameWidth+6, "              ");
    mvaddstr(11, 2*gameWidth+6, "              ");

    myrefresh();
}

void printMsg(char *line) {
    int i;
    move(gameDepth, 2);
    for ( i = 0; i < 2*gameWidth; ++i ) {
        addch( FLOOR_CHAR );
    }

    if ((line != NULL) && (*line != '\0')) {
        char buffer[50];
        snprintf(buffer, sizeof(buffer), " %s ", line);
        mvaddstr(gameDepth, gameWidth+1-(strlen(line))/2, buffer);
    }
    myrefresh();
}

void updateScores() {
    int i;
    char buffer[SCORE_WIDTH+1];

    move(2, 2*gameWidth + 14);
    for ( i = 0; i < SCORE_WIDTH; ++i ) addch(BLANK_CHAR);
    snprintf(buffer, sizeof(buffer), "%d", score);
    addstr(buffer);

    move(3, 2*gameWidth + 14);
    for ( i = 0; i < SCORE_WIDTH; ++i ) addch(BLANK_CHAR);
    snprintf(buffer, sizeof(buffer), "%d", numPieces);
    addstr(buffer);

    move(4, 2*gameWidth + 14);
    for ( i = 0; i < SCORE_WIDTH; ++i ) addch(BLANK_CHAR);
    snprintf(buffer, sizeof(buffer), "%d", numLevels);
    addstr(buffer);
}

int readCh() {
    char ch;
    read(0, &ch, 1);
    return (int)ch;
}

void pauseGame() {
    printMsg("Paused");
    readCh();
    printMsg("");
}

int getAgain() {
    printMsg("Again?");
    int ch = readCh();
    printMsg("");
    return ((ch == 'n') || (ch == 'N') || (ch == 'q') || (ch == 'Q'));
}

void setupScreen(int leftKey, int rightKey, int rotateKey, int dropKey, int pauseKey, int quitKey) {
    int i;
    char buffer[50];

    for ( i = 0; i < gameDepth; ++i ) {
        mvaddch(i, 0, WALL_CHAR);
        addch(WALL_CHAR);
        mvaddch(i, 2*gameWidth+2, WALL_CHAR);
        addch(WALL_CHAR);
    }

    move(gameDepth, 2);
    for ( i = 0; i < 2*gameWidth; ++i ) {
        addch(FLOOR_CHAR);
    }

    mvaddch(gameDepth, 0, CORNER_CHAR);
    addch(CORNER_CHAR);
    mvaddch(gameDepth, 2*gameWidth+2, CORNER_CHAR);
    addch(CORNER_CHAR);

    mvaddstr(0, 2*gameWidth+12, "TETRIS");
    mvaddstr(2, 2*gameWidth+6, "Score:");
    mvaddstr(3, 2*gameWidth+6, "Pieces:");
    mvaddstr(4, 2*gameWidth+6, "Levels:");
    mvaddstr(6, 2*gameWidth+6, "Next:");
    mvaddstr(12, 2*gameWidth+8, "Use keys:");
    mvaddstr(13, 2*gameWidth+8, "=========");
    snprintf(buffer, sizeof(buffer), "Move left:  '%c'", leftKey);
    mvaddstr(14, 2*gameWidth+8, buffer);
    snprintf(buffer, sizeof(buffer), "Move right: '%c'", rightKey);
    mvaddstr(15, 2*gameWidth+8, buffer);
    snprintf(buffer, sizeof(buffer), "Rotate:     '%c'", rotateKey);
    mvaddstr(16, 2*gameWidth+8, buffer);
    snprintf(buffer, sizeof(buffer), "Drop:       '%c'", dropKey);
    mvaddstr(17, 2*gameWidth+8, buffer);
    snprintf(buffer, sizeof(buffer), "Pause:      '%c'", pauseKey);
    mvaddstr(18, 2*gameWidth+8, buffer);
    snprintf(buffer, sizeof(buffer), "Quit:       '%c'", quitKey);
    mvaddstr(19, 2*gameWidth+8, buffer);
}

int checkKeypress(int enabled, int timeout) {
    fd_set fds;
    struct timeval tmout;
    
    FD_ZERO(&fds);
    FD_SET(0, &fds);
    tmout.tv_sec = 0L;
    tmout.tv_usec = timeout;
    return select(enabled, &fds, (fd_set*) NULL, (fd_set*) NULL, &tmout);
}
