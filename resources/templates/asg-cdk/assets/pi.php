<?php
    $pi=0;
    $maxiter = $_GET["maxiter"];
    if (empty($maxiter)) { $maxiter=1000000; };
    print("Maxiter $maxiter\n");
    for ($ii=0; $ii<$maxiter; $ii++) {
        $pi+= 1/($ii*4+1) - 1/($ii*4+2+1);
    };
    $pi*=4;
    print("$pi\n");
?>