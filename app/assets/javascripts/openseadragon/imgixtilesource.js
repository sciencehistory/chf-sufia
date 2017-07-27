/*
 * OpenSeadragon - ImgixTileSource
 *
 * Modification of IIIFTileSource to use imgix.com instead.
 * I don't completely understand all this code, there may be some
 * dead code still in here, work in progress.
 *
 * IN PROGRESS:
 *  * support fetching height/width from fm=json imgix response
 *  * code needs lots of clenaing up, and tests, and then maybe submit to OSD.
 *
 * Copyright (C) 2009 CodePlex Foundation
 * Copyright (C) 2010-2013 OpenSeadragon contributors
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 *
 * - Neither the name of CodePlex Foundation nor the names of its
 *   contributors may be used to endorse or promote products derived from
 *   this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

(function( $ ){

/**
 * @class ImgixTileSource
 * @classdesc OpenSeadragon tile source using imgix.com
 *
 * @memberof OpenSeadragon
 * @extends OpenSeadragon.TileSource
 * @see http://iiif.io/api/image/
 */
$.ImgixTileSource = function( options ){
    /* eslint-disable camelcase */

    this.imgixAutoParam = "compress,format"; // default can be overridden by option

    $.extend( true, this, options );

    // TODO get height/width from imgix fm=json response if not provided.
    if ( !( this.height && this.width && this.baseUrl ) ) {
        throw new Error( 'ImgixTileSource required parameters not provided.' );
    }

    options.tileSizePerScaleFactor = {};

    // N.B. 2.0 renamed scale_factors to scaleFactors
    if ( this.tile_width && this.tile_height ) {
        options.tileWidth = this.tile_width;
        options.tileHeight = this.tile_height;
    } else if ( this.tile_width ) {
        options.tileSize = this.tile_width;
    } else if ( this.tile_height ) {
        options.tileSize = this.tile_height;
    } else if ( this.tiles ) {
        // Version 2.0 forwards
        if ( this.tiles.length == 1 ) {
            options.tileWidth  = this.tiles[0].width;
            // Use height if provided, otherwise assume square tiles and use width.
            options.tileHeight = this.tiles[0].height || this.tiles[0].width;
            this.scale_factors = this.tiles[0].scaleFactors;
        } else {
            // Multiple tile sizes at different levels
            this.scale_factors = [];
            for (var t = 0; t < this.tiles.length; t++ ) {
                for (var sf = 0; sf < this.tiles[t].scaleFactors.length; sf++) {
                    var scaleFactor = this.tiles[t].scaleFactors[sf];
                    this.scale_factors.push(scaleFactor);
                    options.tileSizePerScaleFactor[scaleFactor] = {
                        width: this.tiles[t].width,
                        height: this.tiles[t].height || this.tiles[t].width
                    };
                }
            }
        }
    } else {
        // use the largest of tileOptions that is smaller than the short dimension
        var shortDim = Math.min( this.height, this.width ),
            tileOptions = [256, 512, 1024],
            smallerTiles = [];

        for ( var c = 0; c < tileOptions.length; c++ ) {
            if ( tileOptions[c] <= shortDim ) {
                smallerTiles.push( tileOptions[c] );
            }
        }

        if ( smallerTiles.length > 0 ) {
            options.tileSize = Math.max.apply( null, smallerTiles );
        } else {
            // If we're smaller than 256, just use the short side.
            options.tileSize = shortDim;
        }
    }

    if (!options.maxLevel && !this.emulateLegacyImagePyramid) {
        if (!this.scale_factors) {
            options.maxLevel = Number(Math.ceil(Math.log(Math.max(this.width, this.height), 2)));
        } else {
            options.maxLevel = Math.floor(Math.pow(Math.max.apply(null, this.scale_factors), 0.5));
        }
    }

    $.TileSource.apply( this, [ options ] );
};

$.extend( $.ImgixTileSource.prototype, $.TileSource.prototype, /** @lends OpenSeadragon.ImgixTileSource.prototype */{
    /**
     * Determine if type imgix, or url is an imgix url
     * @function
     * @param {Object|Array} data
     * @param {String} optional - url
     */

    supports: function( data, url ) {
        if (url) {
            var match = (new Regexp('//([^/]+)/')).exec(url);
            if (match && match[1] && match[1].endsWith("imgix.com") || match[1].endsWith("imgix.net")) {
                return true;
            }
        }

        return (data.type && "imgix" == data.type);
    },

    /**
     *
     * @function
     * @param {Object} data - the raw configuration
     * @example
     * {
     *   "@id" : "http://iiif.example.com/prefix/1E34750D-38DB-4825-A38A-B60A345E591C",
     *   "width" : 6000,
     *   "height" : 4000,
     *   "scale_factors" : [ 1, 2, 4 ],
     *   "tile_width" : 1024,
     *   "tile_height" : 1024,
     *   "formats" : [ "jpg", "png" ],
     * }
     */
    configure: function( data, url ){
        data = data || {};
        if (!data["baseUrl"]) {
            data["baseUrl"] = url;
        }
        return data;
    },

    /**
     * Return the tileWidth for the given level.
     * @function
     * @param {Number} level
     */
    getTileWidth: function( level ) {

        if(this.emulateLegacyImagePyramid) {
            return $.TileSource.prototype.getTileWidth.call(this, level);
        }

        var scaleFactor = Math.pow(2, this.maxLevel - level);

        if (this.tileSizePerScaleFactor && this.tileSizePerScaleFactor[scaleFactor]) {
            return this.tileSizePerScaleFactor[scaleFactor].width;
        }
        return this._tileWidth;
    },

    /**
     * Return the tileHeight for the given level.
     * @function
     * @param {Number} level
     */
    getTileHeight: function( level ) {

        if(this.emulateLegacyImagePyramid) {
            return $.TileSource.prototype.getTileHeight.call(this, level);
        }

        var scaleFactor = Math.pow(2, this.maxLevel - level);

        if (this.tileSizePerScaleFactor && this.tileSizePerScaleFactor[scaleFactor]) {
            return this.tileSizePerScaleFactor[scaleFactor].height;
        }
        return this._tileHeight;
    },




    /**
     * Responsible for retrieving the url which will return an image for the
     * region specified by the given x, y, and level components.
     * @function
     * @param {Number} level - z index
     * @param {Number} x
     * @param {Number} y
     * @throws {Error}
     */
    getTileUrl: function( level, x, y ){

        if(this.emulateLegacyImagePyramid) {
            var url = null;
            if ( this.levels.length > 0 && level >= this.minLevel && level <= this.maxLevel ) {
                url = this.levels[ level ].url;
            }
            return url;
        }

        //# constants
        var IIIF_ROTATION = '0',
            //## get the scale (level as a decimal)
            scale = Math.pow( 0.5, this.maxLevel - level ),

            //# image dimensions at this level
            levelWidth = Math.ceil( this.width * scale ),
            levelHeight = Math.ceil( this.height * scale ),

            //## iiif region
            tileWidth,
            tileHeight,
            remoteTileSizeWidth,
            remoteTileSizeHeight,
            remoteTileX,
            remoteTileY,
            remoteTileW,
            remoteTileH,
            remoteSize,
            imgixRectValue

        tileWidth = this.getTileWidth(level);
        tileHeight = this.getTileHeight(level);
        remoteTileSizeWidth = Math.ceil( tileWidth / scale );
        remoteTileSizeHeight = Math.ceil( tileHeight / scale );


        if ( levelWidth < tileWidth && levelHeight < tileHeight ){
            remoteSize = levelWidth;
            imgixRectValue = '';
        } else {
            remoteTileX = x * remoteTileSizeWidth;
            remoteTileY = y * remoteTileSizeHeight;
            remoteTileW = Math.min( remoteTileSizeWidth, this.width - remoteTileX );
            remoteTileH = Math.min( remoteTileSizeHeight, this.height - remoteTileY );

            remoteSize = Math.ceil( remoteTileW * scale );
            imgixRectValue = remoteTileX + "," + remoteTileY + "," + remoteTileW + "," + remoteTileH;
        }


        return this.baseUrl + "?" + this.serializeQueryParams({
            "auto": this.imgixAutoParam,
            "fm": "jpg",
            "rect": imgixRectValue,
            "w": remoteSize
        });
    },

    serializeQueryParams: function(obj) {
      var str = [];
      for(var p in obj)
        if (obj.hasOwnProperty(p)) {
          str.push(encodeURIComponent(p) + "=" + encodeURIComponent(obj[p]));
        }
      return str.join("&");
    }

});

}( OpenSeadragon ));
