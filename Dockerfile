# Use the official PHP Apache image
FROM php:8.2-apache

# Enable error reporting like in your PHP code
RUN echo "error_reporting = E_ALL" >> /usr/local/etc/php/conf.d/errors.ini && \
    echo "display_errors = On" >> /usr/local/etc/php/conf.d/errors.ini

# Install required PHP extensions
RUN docker-php-ext-install pdo pdo_mysql

# Enable Apache rewrite module
RUN a2enmod rewrite

# Set working directory
WORKDIR /var/www/html

# Copy all files to the container
COPY . .

# Install dependencies AFTER code is copied
RUN apt-get update && apt-get install -y unzip git curl && \
    curl -sS https://getcomposer.org/installer | php && \
    php composer.phar install

# Create a default .htaccess if it doesn't exist
RUN if [ ! -f .htaccess ]; then \
    echo "Options -Indexes" > .htaccess && \
    echo "DirectoryIndex index.php" >> .htaccess && \
    echo "RewriteEngine On" >> .htaccess && \
    echo "RewriteCond %{REQUEST_FILENAME} !-f" >> .htaccess && \
    echo "RewriteCond %{REQUEST_FILENAME} !-d" >> .htaccess && \
    echo "RewriteRule ^ index.php [L]" >> .htaccess; \
    fi

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# Expose port 80 (default for Apache)
EXPOSE 80

# Start Apache in foreground
CMD ["apache2-foreground"]
