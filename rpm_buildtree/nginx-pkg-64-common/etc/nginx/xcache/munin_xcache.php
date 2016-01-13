<?php

/******************************************************************************
 *
 * Munin plugin for xcache 
 * 
 *  
 *   For more information: http://www.ohardt.net/dev/munin/ 
 * 
 * 
 */




/*
 * 
 * GRAPH & DATA CONFIG
 * 
 */



$CONFIG_GRAPH = array (

    "mem"       => array(   "title"    => 'XCache Memory Usage',
                            "vlabel"   => 'memory'
                        ),
    "hits"      => array(   "title"    => 'XCache Hits',
                            "vlabel"   => 'hits/sec',
                            "args"     => '--base 1000'
                        ),
    "items"     => array(   "title"    => 'XCache Cached Items',
                            "vlabel"   => 'items'
                        )
                        
);

$CONFIG_DATA_TYPES = array (

    "mem"       => array(   "memory_php_max.label" => 'Max. PHP Memory',
                            "memory_php_cur.label" => 'Available PHP Memory',

                            "memory_var_max.label" => 'Max. VAR Memory',
                            "memory_var_cur.label" => 'Available VAR Memory'
                        ),
    "hits"      => array(   "php_hits.label" => 'php hits',
                            "php_hits.type"  => 'DERIVE',
                            "php_hits.min"   => '0',
                            "php_hits.draw"  => 'LINE2',
                        
                            "php_misses.label" => 'php misses',
                            "php_misses.type"  => 'DERIVE',
                            "php_misses.min"   => '0',
                            "php_misses.draw"  => 'LINE2',                        
                        
                            "var_hits.label" => 'var hits',
                            "var_hits.type"  => 'DERIVE',
                            "var_hits.min"   => '0',
                            "var_hits.draw"  => 'LINE2',                        
                                                
                            "var_misses.label" => 'var misses',
                            "var_misses.type"  => 'DERIVE',
                            "var_misses.min"   => '0',
                            "var_misses.draw"  => 'LINE2',                        
                        ),
    "items"     => array(   "items_php_cur.label" => 'Number of cached PHP items',
                            "items_var_cur.label" => 'Number of cached VAR items'
                        )
                        
);



$CONFIG_DATA_VALUES = array (
    "mem"       => array(   "memory_php_max" => 'php_max',
                            "memory_php_cur" => 'php_cur',

                            "memory_var_max" => 'var_max',
                            "memory_var_cur" => 'var_cur'
                        ),
                        
    "hits"      => array(   "php_hits"   => 'php_hits',
                            "php_misses" => 'php_miss',

                            "var_hits"   => 'var_hits',
                            "var_misses" => 'var_miss'
                        ),
                        
    "items"     => array(   "items_php_cur" => 'php_cached',
                            "items_var_cur" => 'var_cached'
                        )
);






/*
 * 
 * START
 * 
 */





$html_output = ( isset( $_GET["html"] ) );


if( $html_output) {
    echo "<html><pre>";
}


if( !isset( $_GET["what"] ) ) {

    if( $html_output) {
        echo 'no "what" ';
        echo "</pre></html>";
    }
    exit( 0 );
}

$what = $_GET["what"];

if( !munin_xcache_check_type( $what ) ) {
    
    if( $html_output) {
        echo 'invalid "what" ';
        echo "</pre></html>";
    }
    exit( 0 );
}

if( isset( $_GET["config"] ) ) {
    
    munin_xcache_print_config( $what );
    
} else { 

    munin_xcache_print_data( $what );
}

if( $html_output) {
    echo "</pre></html>";
}


exit( 0 );




function munin_xcache_login() {
    
    $_SERVER['PHP_AUTH_USER'] = isset( $_ENV["xcache_uname"] ) ? $_ENV["xcache_uname"] : "uname";
    $_SERVER['PHP_AUTH_PW']   = isset( $_ENV["xcache_pwd"] )   ? $_ENV["xcache_pwd"]   : "pwd";
}



function munin_xcache_check_type( $what ) {
    
    global $CONFIG_GRAPH;
    
    return ( isset( $CONFIG_GRAPH[$what] ) ); 
}



function munin_xcache_print_config( $what ) {
    
    global $CONFIG_GRAPH;
    global $CONFIG_DATA_TYPES;
    
    if( ( !isset( $CONFIG_GRAPH[$what] ) ) || 
        ( !isset( $CONFIG_DATA_TYPES[$what] ) ) ) {
            
        return false;
    }
    
    foreach( $CONFIG_GRAPH[$what] as $key => $val ) {
        print "graph_" . $key . " " . $val . "\n";
    }    
    print "graph_category xcache\n";
        
    foreach( $CONFIG_DATA_TYPES[$what] as $key => $val ) {
        print $key . " " . $val . "\n";
    }    
}



function munin_xcache_print_data( $what ) {

    global $CONFIG_DATA_VALUES;

    if( !isset( $CONFIG_DATA_VALUES[$what] ) ) {
        return false;
    }
    
    $current = $CONFIG_DATA_VALUES[$what];

    $data = munin_xcache_get_data();
    
    // got data ? 
    if( $data === false ) {

        foreach( $current as $key => $value ) {
            print $key . " U\n";
        }
        return false;
    }
    
    foreach( $current as $key => $value ) {
        print $key . ".value " . $data[ $value ] . "\n";
    }
    
    return true;
}



function munin_xcache_get_data() {
    
    $pcnt = xcache_count(XC_TYPE_PHP);
    $vcnt = xcache_count(XC_TYPE_VAR);
    
    $info['php_max'] = 0;
    $info['php_cur'] = 0;
    
    $info['var_max'] = 0;
    $info['var_cur'] = 0;
    
    $info['php_hits']  = 0;
    $info['var_hits']  = 0;
    
    $info['php_miss']  = 0;
    $info['var_miss']  = 0;
    
    $info['php_items']  = 0;
    $info['var_items']  = 0;
    
    $info['php_cached']  = 0;
    $info['var_cached']  = 0;
    
    
    for ($i = 0; $i < $pcnt; $i ++) {
            $data = xcache_info(XC_TYPE_PHP, $i);
    
            $info['php_max']  += $data["size"];
            $info['php_cur']  += $data["avail"];
    
            $info['php_hits'] += $data["hits"];
            $info['php_miss'] += $data["misses"];
    
            $info['php_cached'] += $data["cached"];
    }
    
    for ($i = 0; $i < $vcnt; $i ++) {
            $data = xcache_info(XC_TYPE_VAR, $i);
    
            $info['var_max']  += $data["size"];
            $info['var_cur']  += $data["avail"];
    
            $info['var_hits'] += $data["hits"];
            $info['var_miss'] += $data["misses"];
    
            $info['var_cached'] += $data["cached"];
    }
    
    $info["php_perc"] = round( ( $info['php_max'] == 0 ) ? 0.00 : ( $info['php_cur'] / $info['php_max'] ) * 100, 2 );
    $info["var_perc"] = round( ( $info['var_max'] == 0 ) ? 0.00 : ( $info['var_cur'] / $info['var_max'] ) * 100, 2 );

    return $info;
}



    
?>
