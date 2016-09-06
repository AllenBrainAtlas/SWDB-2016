import os
import matplotlib.pyplot as plt
from scipy.ndimage.filters import gaussian_filter
import numpy as np
from scipy import fftpack
from scipy.ndimage import map_coordinates

def log_fourier_transform(image):
	"""Shifts the supplied image so its mean intensity is 0, then computes the log of the absolute value of the fourier transform.
	Input:
		:numpy.ndarray image : the image to transform
	Output:
		:numpy.ndarray mean_shifted_image : the image with mean shifted to 0
		:numpy.ndarray fft_image : The image, passed through the following transformations (in order): shift mean to 0, FFT, FFTshift, norm squared, log10
			See scipy.fftpack.fft2 and scipy.fftpack.fftshift"""
	mean_shifted_image = image - np.mean(image[:])
	shifted_fft_raw_image = fftpack.fftshift(fftpack.fft2(mean_shifted_image))
	log_fft_image =  np.log10(np.abs(shifted_fft_raw_image) ** 2 + 1) # add one to take care of values too close to 0
	return mean_shifted_image, log_fft_image

def radial_image_intensity(image, x_0, y_0, r, theta=(0.0, np.pi / 4, np.pi / 2, 3 * np.pi / 4), num_interp_points=None):
	"""returns the image's 'radial intensity' around the given point, to a distance of r, for each angle in the iterable theta.
	Input:
		:numpy.ndarray image : The image to transform
		:float x_0, y_0 : The coordinates from which the radial intensity will be computed
		:float r : The distance to integrate along
		:iterable theta : A list, array, or other iterable collection of floats, which are the angles in which to integrate.
	Output:
		theta : the input theta, or the default of 45 degree increments from 0 (inclusive) to 180 (exclusive)
		intensity : the intensity in the corresponding direction. The idea is you can just say plot(theta, intensity) and get something useful."""
	intensity = [image_line_segment_intensity(image, x_0, y_0, x_0 + r * np.cos(t), y_0 + r * np.sin(t), num_steps=num_interp_points) for t in theta]
	return theta, intensity

def image_line_segment_intensity(image, x_0, y_0, x_1, y_1, num_steps=None):
	"""computes the 'mean intensity' of the image along the line segment from (x0,y0) to (x1, y1).
	This is defined as 1/r times the sum of the pixel intensities on the interpolated line between the two endpoints (inclusive)

	Input:
		image : ndarray image
		x0, y0 : the (pixel) coordinates of the start point
		x1, y1 : the (pixel) coordinates of the end point

	Output:
		mean intensity

	Note:
		This is undoubtedly going to be rather crude, because we are interpolating from pixel to pixel. To improve accuracy, use a large number (around 500) num_steps. To improve accuracy further, improve the interpolated_pixel_values function to do an honest-to-goodness integral along a piecewise constant function."""
	r = np.hypot(np.abs(x_0 - x_1), np.abs(y_0 - y_1))
	int_pixels,ds = interpolated_pixel_values(image, x_0, y_0, x_1, y_1, num_steps=num_steps)
	total_intensity =  np.sum(ds * int_pixels)
	return float(total_intensity) / r


def interpolated_pixel_values(image, x_0, y_0, x_1, y_1, num_steps=None, ord=1):
	"""returns the pixel values along the interpolated line between the (pixel) coordinates in the given image, using interpolation of order ord. Uses scipy.ndimage.map_map_coordinates to do the interpolation.
	Input:
		image : image as ndarray
		x_0, y_0 : start coordinates
		x_1, y_1 : end coordinates
		num_steps : number of sample points to take in the middle. By default, this is the ceiling of the distance between the start and end point
		ord : order of interpolation
	Output:
		pixel_values : the image intensity at each sample point
		ds : the step size, for taking Riemann sums

	Note:
		To improve numerical performance, this should be rewritten using the following algorithm:
			1. Compute the points of intersection of the line segment with the horizontal and vertical lines where at least one coordinate is an integer.
			2. Sort those points by the order in which they are hit while traveling from the initial point to the final point
			3. for each sub-interval, return its pixel value and length in the arrays pixel_values, ds
		"""
	if not num_steps:
		num_steps = 200.0
	dx = (x_1 - x_0)/num_steps
	dy = (y_1 - y_0)/num_steps
	ds = np.hypot(dx,dy)
	step_range = np.arange(0,num_steps)
	x_range = x_0 + step_range * dx
	y_range = y_0 + step_range * dy
	pixel_values = map_coordinates(image, np.vstack((x_range, y_range)),order=ord)
	return pixel_values, ds

def save_matrix_as_image(matrix, filename, save_path='', file_extension='png', color_map='gray'):
	"""Saves the given matrix as an image file without axes or excess space around it.
        Input:
        	m : a 2-dimensional ndarray
        	filename : string for the name of the output image
        	save_path : where to save the image. By default this is python's current working directory (see os.getcwd())
        	file_extension : what format to save the image. Default is png
        	color_map : color scheme for the output image. Default is 'gray'"""
	fig = plt.figure(frameon=False)
	ax = plt.Axes(fig, [0., 0., 1., 1.])
	ax.set_axis_off()
	fig.add_axes(ax)
	ax.imshow(matrix, aspect='auto', cmap=color_map)
	fig.savefig(os.path.join(save_path,filename + '.' + file_extension))
	plt.close(fig)

def gaussian_blur(img,sigma=19.6):
	"""Applies a gaussian blur to given image and returns the result. 
         By default, sigma is 19.6, which is roughly equal, in pixels, to 2 degrees of the mouse's visual field (ignoring the warping from spherical correction)"""
	return gaussian_filter(img,sigma)

# A start on the algorithm described in the notes for interpolated_pixel_values
# def image_line_segment_integral(image, x_0, y_0, x_1, y_1):
# 	"""computes the integral over the line segment from (x_0,y_0) to (x_1,y_1) of the piecewise-constant function defined by image."""
# 	steep = np.abs(y_1 - y_0) > np.abs(x_1 - x_0)
# 	m = (y_1 - y_0) / (x_1 - x_0)
# 	b = y_0 / (m * x_0)
# 	x_asc = x_1 >= x_0; y_asc = y_1 >= y_0
# 	if steep:
# 		if y_asc:
# 			y_range = range(np.ceil(y_0),np.floor(y_1),1)
# 			if y_0 != np.ceil(y_0):
# 				y_range.insert(0,y_0)
# 			if y_1 != np.floor(y_1):
# 				y_range.append(y_1)
# 		else:
# 			y_range = range(np.floor(y_0),np.ceil(y_1),-1)
# 			if y_0 != np.floor(y_0):
# 				y_range.insert(0,y_0)
# 			if y_1 != np.ceil(y_1)
# 				y_range.append(y_1)
# 		y_arr = np.asarray(y_range)
# 		x_arr = (y_arr - b)/m
#
# 		intensities = image[x_arr, y_arr]
# 	else:
# 		pass
