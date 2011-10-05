<? 
   $api_key = $_POST["api_key"];

   exec("rm -rf dist/chrome-".$api_key);
   exec("cp -r extension dist/chrome-".$api_key);

   exec("perl -pi -e 's/API_KEY/".$api_key."/' dist/chrome-".$api_key."/*");
   
   exec("/var/lib/gems/1.8/bin/crxmake --pack-extension=dist/chrome-".$api_key." --extension-output=dist/publicmind-". $api_key .".crx --pack-extension-key=publicmind.pem", $out);

   $filename = exec("pwd") . "/dist/publicmind-". $api_key .".crx";

   if (!is_file($filename)) {
   
  die('The file appears to be invalid.'. $filename);
}

$filepath = str_replace('\\', '/', realpath($filename));
$filesize = filesize($filepath);
$filename = substr(strrchr('/'.$filepath, '/'), 1);
$extension = strtolower(substr(strrchr($filepath, '.'), 1));

// use this unless you want to find the mime type based on extension
$mime = 'application/x-chrome-extension';

header('Content-Type: '.$mime);
header('Content-Transfer-Encoding: binary');
header('Content-Length: '.sprintf('%d', $filesize));
header('Expires: 0');
		   header('Pragma: no-cache');


$handle = fopen($filepath, 'rb');
fpassthru($handle);
fclose($handle);

 ?>