/*
Ellipse Workstation 1100 (fictitious computer) Emulator (e1100em)
Backend implementation: SDL2

Copyright (c) 2020 Sampo Hippeläinen (hisahi)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#include <stdlib.h>
#include <SDL2/SDL.h>

#include "../backend.h"
#include "../emulator.h"

struct term_buf {
    char ready;
    const char* buf;
    size_t len;
};
static char cmdbuf[514];

static volatile int quit = 0;
static unsigned long lastcounter = 0;
static SDL_Window* window = NULL;
static SDL_Surface* surface = NULL;
static SDL_Renderer* renderer = NULL;
static SDL_Rect rect;
static SDL_Texture* texbuffer = NULL;
static SDL_Thread* termthread = NULL;
static SDL_mutex* termmutex = NULL;
static volatile struct term_buf termbuffer;

int emu_runtermthread(void* ptr);

void emu_init(const char* title)
{
    if (SDL_Init(SDL_INIT_TIMER | SDL_INIT_VIDEO))
        emu_fail("Cannot init SDL");

    if (SDL_CreateWindowAndRenderer(512, 384, SDL_WINDOW_RESIZABLE,
            &window, &renderer))
        emu_fail("Cannot create window or renderer");
        
    if (!(surface = SDL_GetWindowSurface(window)))
        emu_fail("Cannot get surface");

    termbuffer.ready = 0;
    termbuffer.buf = cmdbuf;
    termbuffer.len = 0;
    if (!(termthread = SDL_CreateThread(&emu_runtermthread,
                                "termthread", (void*)&termbuffer)))
        emu_fail("Cannot create terminal thread");
    
    if (!(termmutex = SDL_CreateMutex()))
        emu_fail("Cannot create terminal mutex");
        
    rect.x = 0;
    rect.y = 0;
    emu_settitle(title);
}

void emu_free(void)
{
    emu_scr_kill();
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
}

int emu_is_grabbed(void)
{
    return window == SDL_GetGrabbedWindow();
}

void emu_grab_input(int shouldGrab)
{
    SDL_SetWindowGrab(window, shouldGrab ? SDL_TRUE : SDL_FALSE);
}

void emu_close_quit(void)
{
    ++quit;
}

void emu_settitle(const char* title)
{
    SDL_SetWindowTitle(window, title);
}

int emu_running(void)
{
    SDL_Event e;
    while (SDL_PollEvent(&e))
    {
        switch (e.type)
        {
        case SDL_QUIT:
            ++quit;
            break;
        case SDL_KEYDOWN:
            if (e.key.keysym.sym == SDLK_F11)
                emu_grab_input(0);
            if (e.key.keysym.sym == SDLK_F12)
            {
                emu_grab_input(0);
                emu_pause_debug();
            }
            break;
        case SDL_MOUSEBUTTONUP:
            if (!emu_is_grabbed() && e.button.button == SDL_BUTTON_LEFT)
                emu_grab_input(1);
            break;
        }
    }
    
    return !quit;
}

unsigned long emu_get_tick_ns(void)
{
    unsigned long newcounter = SDL_GetPerformanceCounter();
    unsigned long difference = newcounter - lastcounter;
    lastcounter = newcounter;
    return difference * NS_PER_S / SDL_GetPerformanceFrequency();
}

inline static size_t emu_getline(char* buf, size_t max)
{
    int c;
    size_t i = 0;

    while (emu_running() && ((c = getchar()) != EOF))
    {
        if (c == '\n')
            break;
        else if (c == '\r')
            continue;
        else if (c == 0)
            emu_delay_ns(1 * NS_PER_MS);
        else if (i < max)
            buf[i++] = c;
    }

    --max;
    buf[i++] = '\0';
    return i;
}

int emu_runtermthread(void* ptr)
{
    volatile struct term_buf* tb = ptr;
    int tmp;
    size_t sz;
    
    while (!quit)
    {
        while (SDL_LockMutex(termmutex))
            SDL_Delay(5);
        tmp = termbuffer.ready;
        SDL_UnlockMutex(termmutex);

        if (tmp)
        {
            SDL_Delay(100);
            continue;
        }

        sz = emu_getline(cmdbuf, 256);
        if (sz > 0)
        {
            while (SDL_LockMutex(termmutex))
                SDL_Delay(5);
            tb->ready = 1;
            tb->buf = cmdbuf;
            tb->len = sz;
            SDL_UnlockMutex(termmutex);
        }
    }

    return 0;
}

int emu_term_hasline(const char** buf, size_t* sz)
{
    int retval = 0;
    if (SDL_LockMutex(termmutex)) return 0;
    if (retval = termbuffer.ready)
    {
        *buf = termbuffer.buf;
        *sz = termbuffer.len;
        termbuffer.ready = 0;
    }
    SDL_UnlockMutex(termmutex);
    return retval;
}

inline void emu_delay_ms(unsigned long ms)
{
    SDL_Delay(ms);
}

inline void emu_delay_ns(unsigned long long ns)
{
    emu_delay_ms((ns + NS_PER_MS - 1) / NS_PER_MS);
}

void emu_get_preferred_pix_format(EmuPixelFormat* pf, SDL_PixelFormatEnum* sdl)
{
    SDL_RendererInfo rinfo;
    size_t i;
    SDL_PixelFormatEnum v;
    if (SDL_GetRendererInfo(renderer, &rinfo))
        emu_fail("Cannot get renderer info");
    
    for (i = 0; i < rinfo.num_texture_formats; ++i)
    {
        v = rinfo.texture_formats[i];
        switch (v)
        {
        case SDL_PIXELFORMAT_ARGB8888:
            *pf = PF_ARGB8888;
            *sdl = v;
            return;
        case SDL_PIXELFORMAT_RGBA8888:
            *pf = PF_RGBA8888;
            *sdl = v;
            return;
        case SDL_PIXELFORMAT_ABGR8888:
            *pf = PF_ABGR8888;
            *sdl = v;
            return;
        case SDL_PIXELFORMAT_BGRA8888:
            *pf = PF_BGRA8888;
            *sdl = v;
            return;
        }
    }

    *pf = PF_ARGB8888;
    *sdl = SDL_PIXELFORMAT_ARGB8888;
}

void emu_scr_init(int w, int h, EmuPixelFormat* pf)
{
    emu_scr_kill();
    SDL_PixelFormatEnum sdlpf;
    emu_get_preferred_pix_format(pf, &sdlpf);
    if (!(texbuffer = SDL_CreateTexture(renderer,
                sdlpf,
                SDL_TEXTUREACCESS_STREAMING, 
                w, h)))
        emu_fail("Cannot create texture");
}

int emu_scr_lock(uint32_t** buf, int* pitch)
{
    void* ptr;
    int x = SDL_LockTexture(texbuffer, NULL, &ptr, pitch);
    *buf = (uint32_t*) ptr;
    return x;
}

void emu_scr_unlock_blit(void)
{
    SDL_UnlockTexture(texbuffer);
    rect.w = surface->w;
    rect.h = surface->h;
    SDL_RenderCopy(renderer, texbuffer, NULL, &rect);
    SDL_RenderPresent(renderer);
}

void emu_scr_kill(void)
{
    if (texbuffer) SDL_DestroyTexture(texbuffer);
}
