# Dockerfile for Abstergo Corp Website
FROM php:7.4-apache

# Enable Apache mod_rewrite for pretty URLs
RUN a2enmod rewrite

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY app/website/ /var/www/html/

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Configure Apache to allow .htaccess
RUN echo '<Directory /var/www/html/> \n\
    Options Indexes FollowSymLinks \n\
    AllowOverride All \n\
    Require all granted \n\
    </Directory>' > /etc/apache2/conf-available/website.conf \
    && a2enconf website

# Expose port
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]
