import std.stdio;
import std.random;

import derelict.sdl2.sdl;

void main()
{
    DerelictSDL2.load();
    DerelictSDL2Image.load();

    if (SDL_Init(SDL_INIT_EVERYTHING))
    {
        writeln("Unable to initialize SDL:\n\t", SDL_GetError());
    }

    SDL_Window* window;
    SDL_Renderer* renderer;

    const int WINDOW_WIDTH = 512;
    const int WINDOW_HEIGHT = 384;
    if (SDL_CreateWindowAndRenderer(
                WINDOW_WIDTH, WINDOW_HEIGHT,
                SDL_WINDOW_OPENGL,
                &window, &renderer
                ))
    {
        writeln("Unable to create window:\n\t", SDL_GetError());
    }

    SDL_SetWindowTitle(window, "Snake");

    const int CELL_SIZE = 16;
    const int COLS = WINDOW_WIDTH / CELL_SIZE;
    const int ROWS = WINDOW_HEIGHT / CELL_SIZE;

    const int SNAKE_MAX_SIZE = COLS * ROWS;

    const float STEP_TIME = 0.25f; // Seconds per step
    float stepTime = 0; // How far we are into a step

    SDL_Rect rect = {0, 0, CELL_SIZE, CELL_SIZE};

    int snakeLength = 1;
    int[SNAKE_MAX_SIZE] xCoords;
    int[SNAKE_MAX_SIZE] yCoords;

    xCoords[0] = COLS/2;
    yCoords[0] = ROWS/2;

    int xVel = 1;
    int yVel = 0;
    int prevXVel = xVel;
    int prevYVel = yVel;

    int foodX = uniform(0, COLS);
    int foodY = uniform(0, ROWS);

    float delta;
    uint minFrameTimeMs = 10;
    float minFrameTime = (cast(float)minFrameTimeMs)/1000.0f;
    ulong prevTime = SDL_GetPerformanceCounter();
    ulong nowTime = SDL_GetPerformanceCounter();
    double countsPerSecond = cast(double)SDL_GetPerformanceFrequency();

    bool running = true;
    SDL_Event event;
    while (running)
    {
        while (SDL_PollEvent(&event))
        {
            switch(event.type)
            {
                case SDL_QUIT:
                    running = false;
                    break;
                case SDL_KEYDOWN:
                    SDL_Keycode keycode = event.key.keysym.sym;
                    if ((keycode == SDLK_w || keycode == SDLK_UP) && prevYVel < 1)
                    {
                       xVel = 0;
                       yVel = -1;
                    }
                    else if ((keycode == SDLK_d || keycode == SDLK_RIGHT) && prevXVel > -1)
                    {
                       xVel = 1;
                       yVel = 0;
                    }
                    else if ((keycode == SDLK_s || keycode == SDLK_DOWN) && prevYVel > -1)
                    {
                       xVel = 0;
                       yVel = 1;
                    }
                    else if ((keycode == SDLK_a || keycode == SDLK_LEFT) && prevXVel < 1)
                    {
                       xVel = -1;
                       yVel = 0;
                    }
                    break;
                default:
                    break;
            }
        }

        prevTime = nowTime;
        nowTime = SDL_GetPerformanceCounter();
        delta = (cast(double)(nowTime-prevTime))/countsPerSecond;

        if (delta < minFrameTime)
        {
            SDL_Delay(minFrameTimeMs-(cast(uint)(delta*1000.0f)));
            delta = minFrameTime;
        }

        stepTime += delta;
        if (stepTime > STEP_TIME)
        {
            stepTime = 0;
        }

        if (stepTime == 0)
        {
            // Update snake pos
            for (int i=snakeLength-1; i>=0; --i)
            {
                xCoords[i+1] = xCoords[i];
                yCoords[i+1] = yCoords[i];
            }
            xCoords[0] = xCoords[1]+xVel;
            yCoords[0] = yCoords[1]+yVel;

            // Teleport at walls
            if (xCoords[0] >= COLS)
            {
                xCoords[0] = 0;
                xVel = 1;
            }
            else if (xCoords[0] < 0)
            {
                xCoords[0] = COLS-1;
                xVel = -1;
            }
            if (yCoords[0] >= ROWS)
            {
                yCoords[0] = 0;
                yVel = 1;
            }
            else if (yCoords[0] < 0)
            {
                yCoords[0] = ROWS-1;
                yVel = -1;
            }

            // Check collision with ourselves
            for (int i=1; i<snakeLength; ++i)
            {
                if (xCoords[0] == xCoords[i] && yCoords[0] == yCoords[i])
                {
                    writeln("You lost!");
                    running = false;
                }
            }

            // Check if we eat food
            if (xCoords[0] == foodX && yCoords[0] == foodY)
            {
                foodX = uniform(0, COLS);
                foodY = uniform(0, ROWS);
                snakeLength++;
                if (snakeLength >= SNAKE_MAX_SIZE)
                {
                    writeln("You won");
                    running = false;
                }
            }

            prevXVel = xVel;
            prevYVel = yVel;
        }

        // Render stuff
        SDL_SetRenderDrawColor(renderer, 0x2D, 0x2D, 0x2D, 0xFF);
        SDL_RenderClear(renderer);

        SDL_SetRenderDrawColor(renderer, 0xFA, 0xFA, 0xFA, 0xFF);
        for (int i=0; i<snakeLength; ++i)
        {
            rect.x = xCoords[i]*CELL_SIZE;
            rect.y = yCoords[i]*CELL_SIZE;

            SDL_RenderFillRect(renderer, &rect);
        }

        SDL_SetRenderDrawColor(renderer, 0xFA, 0x2D, 0x2D, 0xFF);
        rect.x = foodX*CELL_SIZE;
        rect.y = foodY*CELL_SIZE;
        SDL_RenderFillRect(renderer, &rect);

        SDL_RenderPresent(renderer);
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);

    IMG_Quit();
    SDL_Quit();
}

