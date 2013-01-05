/*
 * Copyright (C) 2007 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <stdlib.h>
#include <unistd.h>

#include <fcntl.h>
#include <stdio.h>

#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/types.h>

#include <linux/fb.h>
#include <linux/kd.h>

#include <pixelflinger/pixelflinger.h>

#include "font_10x18_cn.h"
//#include "font_cn_tiny.h"
const unsigned cw_en=10;
#include "minui.h"

typedef struct {
    GGLSurface texture;
    unsigned cwidth;
    unsigned cheight;
    unsigned ascent;
} GRFont;

static GRFont *gr_font = 0;
static GRFont *gr_font_l = 0;
static GGLContext *gr_context = 0;
static GGLSurface gr_font_texture;
static GGLSurface gr_framebuffer[2];
static GGLSurface gr_mem_surface;
static unsigned gr_active_fb = 0;

static int gr_fb_fd = -1;
static int gr_vt_fd = -1;

static struct fb_var_screeninfo vi;

static int get_framebuffer(GGLSurface *fb)
{
    int fd;
    struct fb_fix_screeninfo fi;
    void *bits;

    fd = open("/dev/graphics/fb0", O_RDWR);
    if (fd < 0) {
        perror("cannot open fb0");
        fprintf(stderr, "cannot open fb0");
        return -1;
    }

    if (ioctl(fd, FBIOGET_FSCREENINFO, &fi) < 0) {
        perror("failed to get fb0 info");
        fprintf(stderr, "failed to get fb0 info");
        close(fd);
        return -1;
    }

    if (ioctl(fd, FBIOGET_VSCREENINFO, &vi) < 0) {
        perror("failed to get fb0 info");
        fprintf(stderr, "failed to get fb0 info2");
        close(fd);
        return -1;
    }

    bits = mmap(0, fi.smem_len, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (bits == MAP_FAILED) {
        perror("failed to mmap framebuffer");
        fprintf(stderr, "failed to mmap framebuffer");
        close(fd);
        return -1;
    }

    fb->version = sizeof(*fb);
    fb->width = vi.xres;
    fb->height = vi.yres;
    fb->stride = vi.xres;
    fb->data = bits;
    fb->format = GGL_PIXEL_FORMAT_RGB_565;

    fb++;

    fb->version = sizeof(*fb);
    fb->width = vi.xres;
    fb->height = vi.yres;
    fb->stride = vi.xres;
    fb->data = (void*) (((unsigned) bits) + vi.yres * vi.xres * 2);
    fb->format = GGL_PIXEL_FORMAT_RGB_565;

    return fd;
}

static void get_memory_surface(GGLSurface* ms) {
  ms->version = sizeof(*ms);
  ms->width = vi.xres;
  ms->height = vi.yres;
  ms->stride = vi.xres;
  ms->data = malloc(vi.xres * vi.yres * 2);
  ms->format = GGL_PIXEL_FORMAT_RGB_565;
}

static void set_active_framebuffer(unsigned n)
{
    if (n > 1) return;
    vi.yres_virtual = vi.yres * 2;
    vi.yoffset = n * vi.yres;
    vi.bits_per_pixel = 16;
    if (ioctl(gr_fb_fd, FBIOPUT_VSCREENINFO, &vi) < 0) {
        perror("active fb swap failed");
    }
}

void gr_flip(void)
{
    GGLContext *gl = gr_context;

    /* swap front and back buffers */
    gr_active_fb = (gr_active_fb + 1) & 1;

    /* copy data from the in-memory surface to the buffer we're about
     * to make active. */
    memcpy(gr_framebuffer[gr_active_fb].data, gr_mem_surface.data,
           vi.xres * vi.yres * 2);

    /* inform the display driver */
    set_active_framebuffer(gr_active_fb);
}

void gr_color(unsigned char r, unsigned char g, unsigned char b, unsigned char a)
{
    GGLContext *gl = gr_context;
    GGLint color[4];
    color[0] = ((r << 8) | r) + 1;
    color[1] = ((g << 8) | g) + 1;
    color[2] = ((b << 8) | b) + 1;
    color[3] = ((a << 8) | a) + 1;
    gl->color4xv(gl, color);
}

int getGBCharID(unsigned c1, unsigned c2)
{
	if (c1 >= 0xB0 && c1 <=0xF7 && c2>=0xA1 && c2<=0xFE)
	{
		return (c1-0xB0)*94+c2-0xA1;
	}
	return -1;
}

int getUNICharID(unsigned short unicode)
{
	int i;
	for (i = 0; i < UNICODE_NUM; i++) {
		if (unicode == unicodemap[i]) return i;
	}
	return -1;
}

int gr_measure(const char *s)
{
    return gr_font->cwidth * strlen(s);
}

int gr_text(int x, int y, const char *s)
{
    GGLContext *gl = gr_context;
    GRFont *font = gr_font;
    unsigned off;
	unsigned off2;
	unsigned off3;
	int id;
	unsigned short unicode;

    y -= font->ascent;

    gl->bindTexture(gl, &font->texture);
    gl->texEnvi(gl, GGL_TEXTURE_ENV, GGL_TEXTURE_ENV_MODE, GGL_REPLACE);
    gl->texGeni(gl, GGL_S, GGL_TEXTURE_GEN_MODE, GGL_ONE_TO_ONE);
    gl->texGeni(gl, GGL_T, GGL_TEXTURE_GEN_MODE, GGL_ONE_TO_ONE);
    gl->enable(gl, GGL_TEXTURE_2D);

    while((off = *s++)) {
		if (off < 0x80)
		{
		    off -= 32;
		    if (off < 96) {
				if ((x + cw_en) >= gr_fb_width()) return x;
		        gl->texCoord2i(gl, (off * font->cwidth) - x, 0 - y);
		        gl->recti(gl, x, y, x + cw_en, y + font->cheight);
		    }
		    x += cw_en;
		}
		else
		{
			if ((off & 0xF0) == 0xE0)
			{
				off2 = *s++;
				off3 = *s++;
				unicode = (off & 0x1F) << 12;
				unicode |= (off2 & 0x3F) << 6;
				unicode |= (off3 & 0x3F);
				id = getUNICharID(unicode);
				//LOGI("%X %X %X  %X  %d", off, off2, off3, unicode, id);
				if (id >= 0) {
					if ((x + font->cwidth) >= gr_fb_width()) return x;
				    gl->texCoord2i(gl, ((id % 96) * font->cwidth) - x, (id / 96 + 1) * font->cheight - y);
				    gl->recti(gl, x, y, x + font->cwidth, y + font->cheight);
				    x += font->cwidth;
				} else {
				    x += font->cwidth;
				}
			} else {
			    x += cw_en;
			}
		}
    }

    return x;
}

int gr_text_l(int x, int y, const char *s)
{
	GGLContext *gl = gr_context;
	GRFont *font = gr_font_l;
	unsigned off;

	y -= font->ascent;

	gl->bindTexture(gl, &font->texture);
	gl->texEnvi(gl, GGL_TEXTURE_ENV, GGL_TEXTURE_ENV_MODE, GGL_REPLACE);
	gl->texGeni(gl, GGL_S, GGL_TEXTURE_GEN_MODE, GGL_ONE_TO_ONE);
	gl->texGeni(gl, GGL_T, GGL_TEXTURE_GEN_MODE, GGL_ONE_TO_ONE);
	gl->enable(gl, GGL_TEXTURE_2D);
	
	while((off = *s++)) 
	{
		off -= 32;
		if (off < 96) 
		{
		  gl->texCoord2i(gl, 0 - (gr_fb_width() - y), (off * font->cwidth) - x + 1);
		  gl->recti(gl, gr_fb_width() - y - font->cheight, x, gr_fb_width() - 1 - y, x + font->cwidth);
		}
		x += font->cwidth;
	}

	return x;
}

void gr_fill(int x, int y, int w, int h)
{
    GGLContext *gl = gr_context;
    gl->disable(gl, GGL_TEXTURE_2D);
    gl->recti(gl, x, y, w, h);
}

void gr_fill_l(int x, int y, int w, int h)
{
    GGLContext *gl = gr_context;
    gl->disable(gl, GGL_TEXTURE_2D);
    gl->recti(gl, gr_fb_width() - h, x, gr_fb_width() - y, w);
}

void gr_clear()
{
    gr_color(0,0,0,255);
    gr_fill(0,0, gr_fb_width(), gr_fb_height());
}

void gr_blit(gr_surface source, int sx, int sy, int w, int h, int dx, int dy) {
    if (gr_context == NULL) {
        return;
    }
    GGLContext *gl = gr_context;

    gl->bindTexture(gl, (GGLSurface*) source);
    gl->texEnvi(gl, GGL_TEXTURE_ENV, GGL_TEXTURE_ENV_MODE, GGL_REPLACE);
    gl->texGeni(gl, GGL_S, GGL_TEXTURE_GEN_MODE, GGL_ONE_TO_ONE);
    gl->texGeni(gl, GGL_T, GGL_TEXTURE_GEN_MODE, GGL_ONE_TO_ONE);
    gl->enable(gl, GGL_TEXTURE_2D);
    gl->texCoord2i(gl, sx - dx, sy - dy);
    gl->recti(gl, dx, dy, dx + w, dy + h);
}

unsigned int gr_get_width(gr_surface surface) {
    if (surface == NULL) {
        return 0;
    }
    return ((GGLSurface*) surface)->width;
}

unsigned int gr_get_height(gr_surface surface) {
    if (surface == NULL) {
        return 0;
    }
    return ((GGLSurface*) surface)->height;
}

static void gr_init_font(void)
{
    GGLSurface *ftex, *ftex_l;
    unsigned char *bits, *bits_l, *load_data, *rle;
    unsigned char *in, data;

		//portrait
    gr_font = calloc(sizeof(*gr_font), 1);
    ftex = &gr_font->texture;

    bits = malloc(font.width * font.height);
		load_data = bits;

    ftex->version = sizeof(*ftex);
    ftex->width = font.width;
    ftex->height = font.height;
    ftex->stride = font.width;
    ftex->data = (void*) bits;
    ftex->format = GGL_PIXEL_FORMAT_A_8;
		
		//landscape
		gr_font_l = calloc(sizeof(*gr_font_l), 1);
    ftex_l = &gr_font_l->texture;
    
		bits_l = malloc(font.width * font.height);

    ftex_l->version = sizeof(*ftex);
    ftex_l->width = font.height;
    ftex_l->height = font.width;
    ftex_l->stride = font.height;
    ftex_l->data = (void*) bits_l;
    ftex_l->format = GGL_PIXEL_FORMAT_A_8;

    in = font.rundata;
    while((data = *in++)) {
        memset(load_data, (data & 0x80) ? 255 : 0, data & 0x7f);
        load_data += (data & 0x7f);
    }

		//landscape transformation
		unsigned int i,j;
		for (i = 0; i < font.height; i++)
			for (j = 0; j < font.width; j++)
				bits_l[j * font.height + i] = bits[(font.height - 1 - i) * font.width + j];

    gr_font->cwidth = font.cwidth;
    gr_font->cheight = font.cheight;
    gr_font->ascent = font.cheight - 2;
    
    gr_font_l->cwidth = font.cwidth;
    gr_font_l->cheight = font.cheight;
    gr_font_l->ascent = font.cheight - 2;
}

int gr_init(void)
{
    gglInit(&gr_context);
    GGLContext *gl = gr_context;

    gr_init_font();
    gr_vt_fd = open("/dev/tty0", O_RDWR | O_SYNC);
    if (gr_vt_fd < 0) {
        // This is non-fatal; post-Cupcake kernels don't have tty0.
        perror("can't open /dev/tty0");
    } else if (ioctl(gr_vt_fd, KDSETMODE, (void*) KD_GRAPHICS)) {
        // However, if we do open tty0, we expect the ioctl to work.
        perror("failed KDSETMODE to KD_GRAPHICS on tty0");
        gr_exit();
        return -1;
    }

    gr_fb_fd = get_framebuffer(gr_framebuffer);
    if (gr_fb_fd < 0) {
        perror("failed to get_framebuffer");
        gr_exit();
        return -1;
    }

    get_memory_surface(&gr_mem_surface);

    fprintf(stderr, "framebuffer: fd %d (%d x %d)\n",
            gr_fb_fd, gr_framebuffer[0].width, gr_framebuffer[0].height);

        /* start with 0 as front (displayed) and 1 as back (drawing) */
    gr_active_fb = 0;
    set_active_framebuffer(0);
    gl->colorBuffer(gl, &gr_mem_surface);


    gl->activeTexture(gl, 0);
    gl->enable(gl, GGL_BLEND);
    gl->blendFunc(gl, GGL_SRC_ALPHA, GGL_ONE_MINUS_SRC_ALPHA);

    return 0;
}

void gr_exit(void)
{
    close(gr_fb_fd);
    gr_fb_fd = -1;

    free(gr_mem_surface.data);

    ioctl(gr_vt_fd, KDSETMODE, (void*) KD_TEXT);
    close(gr_vt_fd);
    gr_vt_fd = -1;
}

int gr_fb_width(void)
{
    return gr_framebuffer[0].width;
}

int gr_fb_height(void)
{
    return gr_framebuffer[0].height;
}

gr_pixel *gr_fb_data(void)
{
    return (unsigned short *) gr_mem_surface.data;
}
