import math
import numpy as np
import matplotlib.pyplot as plt
 
 
def through(x):
    return x


def smooth_step(e0, e1, x):
    x = min( 1.0, max( 0.0, (x - e0) / (e1 - e0) ) )
    return x * x * x * (x * (x * 6 - 15) + 10);

def step(c, x):
    if x < c:
        return 0.0
    else:
        return 1.0

def slope_step( c, w, x ):
    if x < c - w * 0.5:
        return 0.0

    elif x < c + w * 0.5:
        return (x - ( c - w * 0.5 ) ) / w

    else:
        return 1.0

def trapezoid( e0, e1, w, x ):
    if x < e0 - w:
        return 0.0

    elif x < e0:
        return ( x - (e0 - w))/w

    elif x < e1:
        return 1.0

    elif x < e1 + w:
        return 1.0 - (x - e1) /w

    else:
        return 0.0


def twin_peaks( e0, e1, w, x ):
    hw = 0.5 * w
    if x < e0 - hw:
        return 0.0;

    elif x < e0:
        return (x - (e0 - hw))/ hw

    elif x < e0 + hw:
        return 1.0 - (x - e0) / hw

    if x < e1 - hw:
        return 0.0;

    elif x < e1:
        return (x - (e1 - hw))/ hw

    elif x < e1 + hw:
        return 1.0 - (x - e1) / hw

    else:
        return 0.0;

def halo( e0, e1, w, x ):
    if x > e1:
        return 0.0
    else:
        return slope_step( e0, w, x )


xs = np.arange( start=0.0, stop=1.001, step=0.001 )


ys = []
for x in xs:
    ys.append( x )
ys = np.array(ys)
plt.plot( xs, ys )
plt.xlabel( 'x' )
plt.ylabel( 'pass_thgourh(x)' )
plt.title( 'pass through' )
plt.savefig( 'plot_pass_through.png' )
plt.clf()

ys = []
for x in xs:
    ys.append( step(0.5, x) )
ys = np.array(ys)
plt.plot( xs, ys )
plt.text( 0.52, 0.2, 'edge' )
plt.xlabel( 'x' )
plt.ylabel( 'step(x)' )
plt.title( 'step' )
plt.savefig( 'plot_step.png' )
plt.clf()

ys = []
for x in xs:
    ys.append( smooth_step(0.2, 0.8, x) )
ys = np.array(ys)
plt.plot( xs, ys )
plt.plot( [0.2, 0.2], [0.0, 1.0], '--' )
plt.plot( [0.8, 0.8], [0.0, 1.0], '--' )
plt.text( 0.22, 0.2, 'edge0' )
plt.text( 0.82, 0.2, 'edge1' )
plt.xlabel( 'x' )
plt.ylabel( 'smooth_step(x)' )
plt.title( 'smooth step' )
plt.savefig( 'plot_smooth_step.png' )
plt.clf()

ys = []
for x in xs:
    ys.append( slope_step(0.5, 0.2, x) )
ys = np.array(ys)
plt.plot( xs, ys )
plt.plot( [0.5, 0.5], [0.0, 1.0], '--' )
plt.plot( [0.4, 0.6], [0.0, 0.0], '--' )
plt.text( 0.51, 0.2, 'edge' )
plt.text( 0.6, 0.01, 'width' )
plt.xlabel( 'x' )
plt.ylabel( 'slope_step(x)' )
plt.title( 'slope step' )
plt.savefig( 'plot_slope_step.png' )
plt.clf()


ys = []
for x in xs:
    ys.append( trapezoid( 0.3, 0.7, 0.2, x ) )
ys = np.array(ys)
plt.plot( xs, ys )
plt.plot( [0.3, 0.3], [0.0, 1.0], '--' )
plt.plot( [0.7, 0.7], [0.0, 1.0], '--' )
plt.plot( [0.1, 0.3], [0.0, 0.0], '--' )
plt.plot( [0.7, 0.9], [0.0, 0.0], '--' )
plt.text( 0.31, 0.2, 'edge0' )
plt.text( 0.71, 0.2, 'edge1' )
plt.text( 0.15, 0.01, 'width' )
plt.text( 0.75, 0.01, 'width' )
plt.xlabel( 'x' )
plt.ylabel( 'trapezoid(x)' )
plt.title( 'trapezoid' )
plt.savefig( 'plot_trapezoid.png' )
plt.clf()


ys = []
for x in xs:
    ys.append( twin_peaks( 0.3, 0.7, 0.2, x ) )
ys = np.array(ys)
plt.plot( xs, ys )
plt.plot( [0.3, 0.3], [0.0, 1.0], '--' )
plt.plot( [0.7, 0.7], [0.0, 1.0], '--' )
plt.plot( [0.2, 0.4], [0.0, 0.0], '--' )
plt.plot( [0.6, 0.8], [0.0, 0.0], '--' )
plt.text( 0.31, 0.2, 'edge0' )
plt.text( 0.71, 0.2, 'edge1' )
plt.text( 0.25, 0.01, 'width' )
plt.text( 0.65, 0.01, 'width' )
plt.xlabel( 'x' )
plt.ylabel( 'twin_peaks(x)' )
plt.title( 'twin peaks' )
plt.savefig( 'plot_twin_peaks.png' )
plt.clf()


ys = []
for x in xs:
    ys.append( halo( 0.5, 0.65, 0.6, x ) )
ys = np.array(ys)
plt.plot( xs, ys )
plt.plot( [0.5,  0.5 ], [0.0, 1.0], '--' )
plt.plot( [0.65, 0.65], [(1.0/0.6)*0.65 - 0.2/0.6, 1.0], '--' )
plt.plot( [0.65, 0.8 ], [(1.0/0.6)*0.65 - 0.2/0.6, 1.0], '--' )
plt.plot( [0.2, 0.8], [0.01, 0.01], '--' )

plt.text( 0.51, 0.2, 'edge0' )
plt.text( 0.66, 0.2, 'cutoff' )
plt.text( 0.25, 0.01, 'width' )
plt.xlabel( 'x' )
plt.ylabel( 'halo(x)' )
plt.title( 'halo' )
plt.savefig( 'plot_halo.png' )
plt.clf()
