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
#include "../io.h"

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

#define INVALID_KEY ((BYTE)0xFF)

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

BYTE emu_convert_key_code(SDL_Keycode key)
{
    switch (key)
    {
    case SDLK_ESCAPE:       return MAKE_KEY_CODE( 0, 0);
    case SDLK_F1:           return MAKE_KEY_CODE( 1, 0);
    case SDLK_F2:           return MAKE_KEY_CODE( 2, 0);
    case SDLK_F3:           return MAKE_KEY_CODE( 3, 0);
    case SDLK_F4:           return MAKE_KEY_CODE( 4, 0);
    case SDLK_F5:           return MAKE_KEY_CODE( 5, 0);
    case SDLK_F6:           return MAKE_KEY_CODE( 6, 0);
    case SDLK_F7:           return MAKE_KEY_CODE( 7, 0);
    case SDLK_F8:           return MAKE_KEY_CODE( 8, 0);
    case SDLK_F9:           return MAKE_KEY_CODE( 9, 0);
    case SDLK_F10:          return MAKE_KEY_CODE(10, 0);
    case SDLK_INSERT:       return MAKE_KEY_CODE(15, 0);
    
    case SDLK_BACKQUOTE:    return MAKE_KEY_CODE( 0, 1);
    case SDLK_1:            return MAKE_KEY_CODE( 1, 1);
    case SDLK_2:            return MAKE_KEY_CODE( 2, 1);
    case SDLK_3:            return MAKE_KEY_CODE( 3, 1);
    case SDLK_4:            return MAKE_KEY_CODE( 4, 1);
    case SDLK_5:            return MAKE_KEY_CODE( 5, 1);
    case SDLK_6:            return MAKE_KEY_CODE( 6, 1);
    case SDLK_7:            return MAKE_KEY_CODE( 7, 1);
    case SDLK_8:            return MAKE_KEY_CODE( 8, 1);
    case SDLK_9:            return MAKE_KEY_CODE( 9, 1);
    case SDLK_0:            return MAKE_KEY_CODE(10, 1);
    case SDLK_MINUS:        return MAKE_KEY_CODE(11, 1);
    case SDLK_EQUALS:       return MAKE_KEY_CODE(12, 1);
    case SDLK_BACKSLASH:    return MAKE_KEY_CODE(13, 1);
    case SDLK_BACKSPACE:    return MAKE_KEY_CODE(14, 1);
    case SDLK_DELETE:       return MAKE_KEY_CODE(15, 1);
    
    case SDLK_TAB:          return MAKE_KEY_CODE( 0, 2);
    case SDLK_q:            return MAKE_KEY_CODE( 1, 2);
    case SDLK_w:            return MAKE_KEY_CODE( 2, 2);
    case SDLK_e:            return MAKE_KEY_CODE( 3, 2);
    case SDLK_r:            return MAKE_KEY_CODE( 4, 2);
    case SDLK_t:            return MAKE_KEY_CODE( 5, 2);
    case SDLK_y:            return MAKE_KEY_CODE( 6, 2);
    case SDLK_u:            return MAKE_KEY_CODE( 7, 2);
    case SDLK_i:            return MAKE_KEY_CODE( 8, 2);
    case SDLK_o:            return MAKE_KEY_CODE( 9, 2);
    case SDLK_p:            return MAKE_KEY_CODE(10, 2);
    case SDLK_LEFTBRACKET:  return MAKE_KEY_CODE(11, 2);
    case SDLK_RIGHTBRACKET: return MAKE_KEY_CODE(12, 2);
    case SDLK_HELP:         
    case SDLK_HOME:         return MAKE_KEY_CODE(15, 2);
    
    case SDLK_LCTRL:   
    case SDLK_RCTRL:        return MAKE_KEY_CODE( 0, 3);
    case SDLK_a:            return MAKE_KEY_CODE( 1, 3);
    case SDLK_s:            return MAKE_KEY_CODE( 2, 3);
    case SDLK_d:            return MAKE_KEY_CODE( 3, 3);
    case SDLK_f:            return MAKE_KEY_CODE( 4, 3);
    case SDLK_g:            return MAKE_KEY_CODE( 5, 3);
    case SDLK_h:            return MAKE_KEY_CODE( 6, 3);
    case SDLK_j:            return MAKE_KEY_CODE( 7, 3);
    case SDLK_k:            return MAKE_KEY_CODE( 8, 3);
    case SDLK_l:            return MAKE_KEY_CODE( 9, 3);
    case SDLK_SEMICOLON:    return MAKE_KEY_CODE(10, 3);
    case SDLK_QUOTE:        return MAKE_KEY_CODE(11, 3);
    case SDLK_PAGEUP:       return MAKE_KEY_CODE(12, 3);
    case SDLK_RETURN:       return MAKE_KEY_CODE(13, 3);
    case SDLK_UP:           return MAKE_KEY_CODE(15, 3);
    
    case SDLK_LSHIFT:       return MAKE_KEY_CODE( 0, 4);
    case SDLK_PAGEDOWN:     return MAKE_KEY_CODE( 1, 4);
    case SDLK_z:            return MAKE_KEY_CODE( 2, 4);
    case SDLK_x:            return MAKE_KEY_CODE( 3, 4);
    case SDLK_c:            return MAKE_KEY_CODE( 4, 4);
    case SDLK_v:            return MAKE_KEY_CODE( 5, 4);
    case SDLK_b:            return MAKE_KEY_CODE( 6, 4);
    case SDLK_n:            return MAKE_KEY_CODE( 7, 4);
    case SDLK_m:            return MAKE_KEY_CODE( 8, 4);
    case SDLK_COMMA:        return MAKE_KEY_CODE( 9, 4);
    case SDLK_PERIOD:       return MAKE_KEY_CODE(10, 4);
    case SDLK_SLASH:        return MAKE_KEY_CODE(11, 4);
    case SDLK_RSHIFT:       return MAKE_KEY_CODE(13, 4);
    case SDLK_LEFT:         return MAKE_KEY_CODE(14, 4);
    case SDLK_RIGHT:        return MAKE_KEY_CODE(15, 4);
    
//  case SDLK_CAPSLOCK:     return MAKE_KEY_CODE( 0, 5);
            // needs to be handled separately
    case SDLK_LALT:         return MAKE_KEY_CODE( 1, 5);
    case SDLK_SPACE:        return MAKE_KEY_CODE( 2, 5);
    case SDLK_RALT:         return MAKE_KEY_CODE(11, 5);
    case SDLK_DOWN:         return MAKE_KEY_CODE(15, 5);
    
    case SDLK_KP_LEFTPAREN: return MAKE_KEY_CODE( 0, 6);
    case SDLK_KP_7:         return MAKE_KEY_CODE( 1, 6);
    case SDLK_KP_4:         return MAKE_KEY_CODE( 2, 6);
    case SDLK_KP_1:         return MAKE_KEY_CODE( 3, 6);
    case SDLK_KP_0:         return MAKE_KEY_CODE( 4, 6);
    case SDLK_KP_RIGHTPAREN:return MAKE_KEY_CODE( 8, 6);
    case SDLK_KP_8:         return MAKE_KEY_CODE( 9, 6);
    case SDLK_KP_5:         return MAKE_KEY_CODE(10, 6);
    case SDLK_KP_2:         return MAKE_KEY_CODE(11, 6);
    
    case SDLK_KP_DIVIDE:    return MAKE_KEY_CODE( 0, 7);
    case SDLK_KP_9:         return MAKE_KEY_CODE( 1, 7);
    case SDLK_KP_6:         return MAKE_KEY_CODE( 2, 7);
    case SDLK_KP_3:         return MAKE_KEY_CODE( 3, 7);
    case SDLK_KP_MULTIPLY:  return MAKE_KEY_CODE( 8, 7);
    case SDLK_KP_MINUS:     return MAKE_KEY_CODE( 9, 7);
    case SDLK_KP_PLUS:      return MAKE_KEY_CODE(10, 7);
    case SDLK_KP_ENTER:     return MAKE_KEY_CODE(11, 7);
    }
    return INVALID_KEY;
}

int emu_running(void)
{
    SDL_Event e;
    BYTE tmp;
    while (SDL_PollEvent(&e))
    {
        switch (e.type)
        {
        case SDL_QUIT:
            ++quit;
            break;
        case SDL_KEYDOWN:
            // handle caps
            if ((e.key.keysym.mod & KMOD_CAPS) == KMOD_CAPS)
                io_keyb_keydown(MAKE_KEY_CODE(0, 5));
            else
                io_keyb_keyup(MAKE_KEY_CODE(0, 5));
            if (e.key.keysym.sym == SDLK_F11)
                emu_grab_input(0);
            else if (e.key.keysym.sym == SDLK_F12
                  || e.key.keysym.sym == SDLK_PAUSE)
            {
                emu_grab_input(0);
                emu_pause_debug();
            }
            else
            {
                tmp = emu_convert_key_code(e.key.keysym.sym);
                if (tmp != INVALID_KEY)
                    io_keyb_keydown(tmp);
            }
            break;
        case SDL_KEYUP:
            // handle caps
            if ((e.key.keysym.mod & KMOD_CAPS) == KMOD_CAPS)
                io_keyb_keydown(MAKE_KEY_CODE(0, 5));
            else
                io_keyb_keyup(MAKE_KEY_CODE(0, 5));
            tmp = emu_convert_key_code(e.key.keysym.sym);
            if (tmp != INVALID_KEY)
                io_keyb_keyup(tmp);
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
