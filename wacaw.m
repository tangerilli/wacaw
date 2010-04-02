//
//  wacaw.m
//
//  Created by HXR on 3/7/06.
//  Copyright (C) 2006 HXR (hxr@users.sourceforge.net). 
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA
//

#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <string.h>
#include <assert.h>

#import <Foundation/Foundation.h>
#import <QuickTime/QuickTime.h>
#import <CoreServices/CoreServices.h>
#import <Carbon/Carbon.h>

#include "base64.h"

// Globals

#define FILENAME_BUFFER_SIZE  1024
const double BASE64_ENCODE_SIZE_FACTOR = (1.0/3.0+1.0);

static char * versionString = "version 0.40";

static int    verboseFlag   = 0;
static int    videoFlag     = 0;
static int    noAudioFlag   = 0;
static int    toClipboardFlag= 0;
static int	  continuousFlag = 0;

static char * filename      = NULL;
static int    imageWidth    = 640;
static int    imageHeight   = 480;
static int    imageFormat   = kQTFileTypeJPEG;
static int	  numberOfCaptures = 1;
static int    delay = 0;
// QSIF as standard video size (reduces video size dramatically *g*)
static int    videoWidth    = 160;
static int    videoHeight   = 120;
static int    videoFormat   = kQTFileTypeAVI;
static int    duration      = 15;

static int    filenameNecessary = 1;
static int    listDevices   = 0;
static int    selectedVideoDevice = -1;
static int    selectedVideoInput = -1;

// QT data reference
static Handle   dataRef;
static OSType   dataTypeRef;

// Information about options

static struct option longOptions[] =
{
  // These options set a flag. 
  {"verbose", no_argument,       &verboseFlag, 1},
  {"brief",   no_argument,       &verboseFlag, 0},
  {"jpeg",    no_argument,       &imageFormat, kQTFileTypeJPEG}, 
  {"tiff",    no_argument,       &imageFormat, kQTFileTypeTIFF}, 
  {"png",     no_argument,       &imageFormat, kQTFileTypePNG}, 
  {"gif",     no_argument,       &imageFormat, kQTFileTypeGIF}, 
  {"bmp",     no_argument,       &imageFormat, kQTFileTypeBMP}, 
  {"pict",    no_argument,       &imageFormat, kQTFileTypePicture}, 
  {"video",   no_argument,       &videoFlag, 1}, 
  {"no-audio",no_argument,       &noAudioFlag, 1}, 
  {"to-clipboard",no_argument,   &toClipboardFlag, 1}, 
  {"continous",no_argument,      &continuousFlag, 1},
  
  // These options don't set a flag.
  // We distinguish them by their indices. 
  {"help",    no_argument,       0, 'h'},
  {"usage",   no_argument,       0, 'h'},
  {"version", no_argument,       0, 'v'},
  {"width",   required_argument, 0, 'x'},
  {"height",  required_argument, 0, 'y'},
  {"SQSIF",   no_argument,       0, '1'},
  {"QSIF",    no_argument,       0, '2'},
  {"QCIF",    no_argument,       0, '3'},
  {"SIF",     no_argument,       0, '4'},
  {"CIF",     no_argument,       0, '5'},
  {"VGA",     no_argument,       0, '6'},
  {"SVGA",    no_argument,       0, '7'},
  {"list-devices",    no_argument,       0, 'L'},
  {"video-device",    required_argument, 0, 'd'},
  {"video-input",     required_argument, 0, 'i'},
  {"num-frames",     required_argument, 0, 'n'},
  {"duration",        required_argument, 0, 'D'}, 
  {"delay", required_argument, 0, 't'},
  {0, 0, 0, 0}
};

// Shouldn't usage just read from the longOptions?

static void  usage(char * argv[])
{
  printf("%s\n", versionString);
  printf("Usage: %s [-h] [options] [filename]\n", argv[0]);
  printf("  -h / --help        : print this help message\n");
  printf("       --usage       : print this help message\n");
  printf("  -v / --version     : prints out version information\n");
  printf("       --verbose     : more messages about what is going on\n");
  printf("       --brief       : fewer messages about what is going on (default)\n");
  printf("       --video       : record a video\n");
  printf("       --continous   : keep saving frames\n");
  printf("  -t / --delay       : delay between captures (only used if continous is specified)\n");
  printf("       --no-audio    : do not record audio\n");
  printf("  -D / --duration <#>: specify the duration of the video (default: 15 sec.)\n");
  printf("       --to-clipboard: copy image just taken to clipboard\n");
  printf("       --jpeg        : save image in JPEG format (default)\n");
  printf("       --tiff        : save image in TIFF format\n");
  printf("       --png         : save image in PNG format\n");
  printf("       --gif         : save image in GIF format\n");
  printf("       --bmp         : save image in BMP format\n");
  printf("       --pict        : save image in PICT format\n");
  printf("  -x / --width  <#>  : specify the width of the image / video \n");
  printf("  -y / --height <#>  : specify the height of the image / video \n");
  printf("       --SVGA        : the image / video should have 'SVGA'  size (800x600)\n");
  printf("       --VGA         : the image / video should have 'VGA'   size (640x480)\n");
  printf("       --CIF         : the image / video should have 'CIF'   size (352x288)\n");
  printf("       --SIF         : the image / video should have 'SIF'   size (320x240)\n");
  printf("       --QCIF        : the image / video should have 'QCIF'  size (176x144)\n");
  printf("       --QSIF        : the image / video should have 'QSIF'  size (160x120)\n");
  printf("       --SQSIF       : the image / video should have 'SQSIF' size (160x96)\n");
  printf("  -L / --list-devices  : list the devices available\n");
  printf("  -d / --video-device <#>  : specify which device should be used\n");
  printf("  -i / --video-input  <#>  : specify which input should be used (must specify device)\n");
  printf("  -n / --num-frames   <#>  : specify how many pictures to take before\n");
  printf("                                  final image is captured (picture mode only)\n");
  printf("       filename      : needed unless only listing available devices (-L) or using help (-h)\n");
}


static char * getFiletypeExtension(int format)
{
  if (format == kQTFileTypeJPEG) 
    return "jpeg";
  
  if (format == kQTFileTypeTIFF) 
    return "tiff";
  
  if (format == kQTFileTypePNG) 
    return "png";
  
  if (format == kQTFileTypeGIF) 
    return "gif";
  
  if (format == kQTFileTypeBMP) 
    return "bmp";
  
  if (format == kQTFileTypePicture) 
    return "pict";
  
  if (format == kQTFileTypeAVI)
    return "avi";
  
  return "unknown";
}


static void  processArguments(int argc, char * argv[]) 
{
  int c, optionIndex = 0;
  
  // Process command-line arguments
  
  while ((c = getopt_long(argc, argv, "hvx:y:Ld:i:n:t:", longOptions, &optionIndex)) != -1) 
  {
    switch (c)
    {
      case 0:
        // If this option set a flag, do nothing else now. 
        if (longOptions[optionIndex].flag != 0)
          break;
        printf("option %s", longOptions[optionIndex].name);
        if (optarg)
          printf(" with arg %s", optarg);
        printf("\n");
        break;
        
        case '1':
        imageWidth = videoWidth = 128;
        imageHeight = videoHeight = 96;
        break;
        
        case '2':
        imageWidth = videoWidth = 160;
        imageHeight = videoHeight = 120;
        break;
        
        case '3':
        imageWidth = videoWidth = 176;
        imageHeight = videoHeight = 144;
        break;
        
        case '4':
        imageWidth = videoWidth = 320;
        imageHeight = videoHeight = 240;
        break;
        
        case '5':
        imageWidth = videoWidth = 352;
        imageHeight = videoHeight = 288;
        break;
        
        case '6':
        imageWidth = videoWidth = 640;
        imageHeight = videoHeight = 480;
        break;
        
        case '7':
        imageWidth = videoWidth = 800;
        imageHeight = videoHeight = 600;
        break;
        
        case 'x':
        imageWidth = videoWidth = atoi(optarg);
        break;
        
        case 'y':
        imageHeight = videoHeight = atoi(optarg);
        break;
        
        case 'L':
        listDevices = 1;
        filenameNecessary = 0;
        break;
        
        case 'd':
        selectedVideoDevice = atoi(optarg);
        break;
        
        case 'n':
        numberOfCaptures = atoi(optarg);
        break;
          
        case 't':
        delay = atoi(optarg);
        break;
            
        case 'i':
        selectedVideoInput = atoi(optarg);
        break;
            
        case 'v':
        printf("%s: %s\n", argv[0], versionString);
        break;
        
        case 'D':
        duration = atoi(optarg);
        break;
        
        case '?':
        // getopt_long already printed an error message. 
        // unknown or ambiguous option
        
        case ':':
        // getopt_long already printed an error message. 
        // missing argument
        
        case 'h':
        default:
        filenameNecessary = 0;
        usage(argv);
        exit(0);
    }
  }
  
  // Instead of reporting `--verbose'
  //    and `--brief' as they are encountered,
  //    we report the final status resulting from them. 
  if (verboseFlag) 
  {
    puts("verbose flag is set");
    if (videoFlag) 
      puts("video flag is set");
  }
  
  // Save the filename if there is one
  if (optind < argc)
  {
    filename = argv[optind++];
  }
  else if (filenameNecessary)  //  thie is the normal case
  {
    printf("You must specify a filename for the image! [see '%s --help' for assistance]\n", argv[0]);
    exit(0);
  }
  
  // Print any remaining command line arguments (not options). 
  if (optind < argc)
  {
    printf("non-option ARGV-elements: ");
    while (optind < argc)
      printf("%s ", argv[optind++]);
    putchar('\n');
  }
}

/// characterizes a given POSIX-path
enum ePathType { fileOnly = 1, relativeDir, absoluteDir };

/// returns type of given POSIX path
static enum ePathType checkPathType(const char* path)
{
	assert(path != NULL);
	// has to include a directory, absolute path if it starts with /
	return (strchr(path, '/') != NULL ? (path[0] == '/' ? absoluteDir : relativeDir) : fileOnly);
}

/// extends a given POSIX-path to a fully qualified path
static void extendToFullPosixPath(const char * path, char * fullPath)
{
  /*
   // get current path via main bundle
   CFBundleRef mainBundle  = CFBundleGetMainBundle();
   CFURLRef url            = CFBundleCopyBundleURL(mainBundle);
   // get POSIX-path from bundle URL
   CFStringRef sr          = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
   */
  enum ePathType pathType = checkPathType(path);  // check path type of given path
  
  assert(strlen(path) < FILENAME_BUFFER_SIZE);
  
  if (pathType == relativeDir || pathType == fileOnly) 
  {
    char location[FILENAME_BUFFER_SIZE];
    
    if (getcwd(location, FILENAME_BUFFER_SIZE) == NULL) 
    {
      fprintf(stderr, "error in call to getcwd() - errno = %d\n", errno);
      exit(errno);
    }
    
    assert(strlen(location) + strlen(path) < FILENAME_BUFFER_SIZE);
    
    sprintf(fullPath, "%s/%s", location, path);  // append path to cwd
  }
  else // full path
  {
    sprintf(fullPath, "%s", path);  // just copy
  }
}

static char* getFullFilename( const char* fn, int fileIndex )
{
  char buffer[FILENAME_BUFFER_SIZE];
  char* extPath = malloc(FILENAME_BUFFER_SIZE);  // temporary filename storage
  
  if (fileIndex == 0)
  {
    // need to set extension based on image_format / videoFormat
    sprintf(buffer, "%s.%s", (fn) ? fn : "wacaw-capture", getFiletypeExtension(videoFlag ? videoFormat : imageFormat));
  }
  else
  {
    // need to set extension based on image_format / videoFormat
    sprintf(buffer, "%s_%d.%s", (fn) ? fn : "wacaw-capture", fileIndex, getFiletypeExtension(videoFlag ? videoFormat : imageFormat));
  }
  
  // tzeeniewheenie: now extend buffer to fully qualified path
  extendToFullPosixPath(&buffer[0], extPath);
  return extPath;
}

BOOL fileIndexExists(const char* fn, int fileIndex)
{
  char* actualName = getFullFilename(fn, fileIndex);
  NSString* nameString = [[NSString alloc] initWithCString: actualName encoding: NSASCIIStringEncoding]; 
  BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:nameString];
  return fileExists;
}

static unsigned char* readFile( const char* fn, int* size  )
{
  // open and count size
  FILE* file = fopen(fn, "r");
  *size = 0;
  while(!feof(file))
  {
    fgetc(file);
    (*size)++;
  }
  rewind(file);
  // now return data
  unsigned char* data = malloc(*size);
  *size = 0;
  while(!feof(file))
  {
    data[*size] = fgetc(file);
    (*size)++;
  }
  fclose(file);
  return data;
}



int  main(int argc, char * argv[]) 
{
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  OSErr               error = noErr;
  ComponentResult     result = 0;
  SeqGrabComponent    sequenceGrabber = NULL;
  PicHandle           picture = NULL;
  GraphicsExportComponent graphicsExporter = NULL;
  Rect                bounds;
  
  processArguments(argc, argv);
  
  error = EnterMovies();
  
  if (error) 
  {
    printf("Error: EnterMovies() returned error %d!\n", error);
    return 1;
  }
  
  sequenceGrabber = OpenDefaultComponent(SeqGrabComponentType, 0);  // open the default sequence grabber
  
  if (!sequenceGrabber) 
  {
    printf("Error: OpenDefaultComponent() returned no sequence grabber component!\n");
    return 2;
  }
  
  error = SGInitialize(sequenceGrabber);  // initialize the sequence grabber
  
  SeqGrabFrameInfo info;
  
  SGDeviceList list = NULL;
  int i, j;
  
  bounds.top = 0;
  bounds.left = 0;
  // if video flag is set, use video values; this is only to preserve different defaults
  // for video and pictures
  bounds.right = videoFlag ? videoWidth : imageWidth;
  bounds.bottom = videoFlag ? videoHeight : imageHeight;
  
  // initializes channels
  result = SGNewChannel(sequenceGrabber, VideoMediaType, &info.frameChannel);
  if(verboseFlag && result != noErr) 
    printf("SGNewChannel failed for VideoMediaType.\n");
  
  result = SGSetChannelBounds(info.frameChannel, &bounds);
  if(verboseFlag && result != noErr) 
    printf("SGSetChannelBounds failed.\n");
  
  result = SGSetChannelUsage(info.frameChannel, seqGrabRecord);
  if(verboseFlag && result != noErr) 
    printf("SGSetChannelUsage failed.\n");
  
  
  // nErr =SGSetChannelUsage(*sgchanVideo, lUsage | seqGrabPlayDuringRecord);
  
  if (listDevices || (selectedVideoDevice >= 0)) 
  {
    result = SGGetChannelDeviceList(info.frameChannel, sgDeviceListDontCheckAvailability | sgDeviceListIncludeInputs, &list);
    
    if (verboseFlag && (result != noErr)) 
      printf("SGGetChannelDeviceList failed (%ld).\n", result);
  }
  
  // listing devices is now a standalone option, unless a filename *is* specified
  
  if (listDevices) 
  {
    if (list == NULL) 
    {
      printf("The list is empty.\n");
    }
    else 
    {
      printf("There are %d devices in the list.\n", (**list).count);
      printf("The current selection is %d.\n", (**list).selectedIndex);
      
      for (i = 0; i < (**list).count; i++) 
      {
        CFStringRef buffer = CFStringCreateWithPascalString(kCFAllocatorDefault, (**list).entry[i].name, kCFStringEncodingASCII);
        printf(" %d - %s [%s] [%s]\n", i, [(NSString *)buffer cString], 
               ((**list).entry[i].flags & sgDeviceNameFlagDeviceUnavailable) ? "is not available" : "is available",
               ((**list).entry[i].flags & sgDeviceNameFlagShowInputsAsDevices) ? "has inputs" : "has no inputs");
        
        SGDeviceInputList inputList = (**list).entry[i].inputs;
        
        if (inputList != NULL) 
        {
          printf("    There are %d inputs for this device (%d).\n", (**inputList).count, i);
          printf("    The current selection is %d.\n", (**inputList).selectedIndex);
          
          for (j = 0; j < (**inputList).count; j++) 
          {
            buffer = CFStringCreateWithPascalString(kCFAllocatorDefault, (**inputList).entry[j].name, kCFStringEncodingASCII);
            printf("   %d - %s [%s]\n", j, [(NSString *) buffer cString], 
                   ((**inputList).entry[j].flags & sgDeviceInputNameFlagInputUnavailable) ? "is not available" : "is available");
          }
        }
      }
    }
    
    if (filename == NULL) 
    {
      SGDisposeDeviceList(sequenceGrabber, list);
      CloseComponent(sequenceGrabber);
      exit(0);
    }
  }
  
  if ((selectedVideoDevice >= 0) && (list != NULL)) 
  {
    result = SGSetChannelDevice(info.frameChannel, (**list).entry[selectedVideoDevice].name);
    
    if (verboseFlag && (result != noErr)) 
      printf("SGSetChannelDevice failed for the selected device (%ld).\n", result);
    else 
      if (selectedVideoInput >= 0) 
      {
        result = SGSetChannelDeviceInput(info.frameChannel, selectedVideoInput);
        
        if (verboseFlag && (result != noErr)) 
            printf("SGSetChannelDeviceInput failed for the selected input (%ld).\n", result);
      }
  }
  
  if (list != NULL) 
    result = SGDisposeDeviceList(sequenceGrabber, list);
  
  
  if(!noAudioFlag && videoFlag) 
  {
    // Set up the sound-channel, for video recording
    
    SGChannel soundComponent;
    
    result = SGNewChannel(sequenceGrabber, SoundMediaType, &soundComponent);
    if (verboseFlag && result != noErr) 
      printf("SGNewChannel failed for SoundMediaType.\n");
    
    result = SGSetChannelUsage(soundComponent, seqGrabRecord);
    if(verboseFlag && result != noErr) 
      printf("SGSetChannelUsage failed.\n");
  }
  
   
  if (!videoFlag)  // Capture an image
  {
    int fileIndex = 1;
    while (fileIndexExists(filename, fileIndex))
    {
      fileIndex++;
    }
    printf("Next free index is %d\n", fileIndex);
    
    // no video flag; take a picture
    do
    {
        // Create a QT data reference from the filename
        char* extPath = getFullFilename(filename, fileIndex);
        result = QTNewDataReferenceFromFullPathCFString(CFStringCreateWithCString(kCFAllocatorDefault, extPath, kCFStringEncodingASCII),
                                                        kQTNativeDefaultPathStyle, 0, &dataRef, &dataTypeRef);
        free(extPath);
        if (result != noErr) 
        {
          printf("Error: could not create a data reference:\nfilename: %s\n", extPath);
          return -1;
        }
      
        for (i = 0; i < numberOfCaptures; i++) 
        {	
            result = SGGrabPict(sequenceGrabber, &picture, &bounds, 0, grabPictOffScreen);
        
            if (result) 
            {
                printf("Error: SGGrabPict() returned error %ld!\n", (long) result);
                // couldntGetRequiredComponent
                return 3;
            }
        }

        // save picture to file
        printf("Saving to file\n");
        OpenADefaultComponent(GraphicsExporterComponentType, imageFormat, &graphicsExporter);
        
        if (!graphicsExporter) 
        {
          printf("Error: OpenADefaultComponent() returned no graphics export component!\n");
          return 4;
        }
        
        result = GraphicsExportSetInputPicture(graphicsExporter, picture);
        
        // use data reference for output
        result = GraphicsExportSetOutputDataReference(graphicsExporter, dataRef, dataTypeRef);
        
        GraphicsExportDoExport(graphicsExporter, NULL);
        
        if (toClipboardFlag)
        {
          // FEATURE REQUEST: copy to clipboard
          // UPDATE: learned some more about using CF version of Pasteboard;
          // The CFPasteboardRef & Co. as such are only 10.4+, some useful functions 
          // even 10.5+. So I did some research on how to do this for at least 10.1+.
          // Solution: Scrap Manager. Nice warnings about coding deprecated stuff. :p
          // Uses carbon framework.
          OSStatus err;
          ScrapRef currScrap;
          err = ClearCurrentScrap();
          if(err != noErr)
              printf("Error: Clearing clipboard failed.");
          else
          {
            err = GetCurrentScrap( &currScrap );
            if(err != noErr)
              printf("Error: Getting the clipboard failed.");
            else
            {
              // we can use the PicHandle we got from SGGrabPict
              err = PutScrapFlavor( currScrap, kScrapFlavorTypePicture,
                                   kScrapFlavorMaskNone, GetHandleSize((Handle)picture), 
                                   *picture );
              
              if( err != noErr )
                printf("Error: Putting image to clipboard failed.");

              int size = 0;
              char* fn = getFullFilename(filename, 0);
              unsigned char* picData = readFile(fn, &size);
              free(fn);
              
              // get bytes and stuff'em into new array
              // size and data for base64 encoding
              unsigned char* b64d = malloc((int)round(size * BASE64_ENCODE_SIZE_FACTOR));
              int b64l;
              encodeBase64( (unsigned char*)picData, size, b64d, &b64l );
              free(picData);
              
              err = PutScrapFlavor( currScrap, kScrapFlavorTypeText,
                                   kScrapFlavorMaskNone, b64l, b64d );
              free(b64d);
              
              if( err != noErr )
                printf("Error: Putting base64 encoded image to clipboard failed.");
            }
          }
        }
        fileIndex++;
        if (continuousFlag == 1 && delay)
        {
          sleep(delay);
        }
    } while (continuousFlag == 1);
    CloseComponent(sequenceGrabber);
    CloseComponent(graphicsExporter);
  }
  else  //  Record the video
  {
    // Create a QT data reference from the filename
    char* extPath = getFullFilename(filename, 0);
    result = QTNewDataReferenceFromFullPathCFString(CFStringCreateWithCString(kCFAllocatorDefault, extPath, kCFStringEncodingASCII),
                                                    kQTNativeDefaultPathStyle, 0, &dataRef, &dataTypeRef);
    free(extPath);
    if (result != noErr) 
    {
      printf("Error: could not create a data reference:\nfilename: %s\n", extPath);
      return -1;
    }
    
    // video flag is set; so we start off a x sec. video
    // graphics world has to be set or port error (-903) will be raised
    SGSetGWorld(sequenceGrabber, NULL, NULL);
    
    if (verboseFlag) 
    {
      printf("video size: (%d x %d)\n", videoWidth, videoHeight);
      printf("duration: %d seconds\n", duration);
    }
    
    // set the output file with grab-to-disk option
    if( SGSetDataRef(sequenceGrabber, dataRef, dataTypeRef, seqGrabRecord | seqGrabToDisk) != noErr )
      printf("Error: Couldn't set data ref.\n");
    // prepare recording
    result = SGPrepare(sequenceGrabber, false, true);
    if( result != noErr )
      printf("Error: SGPrepare failed (%d).\n", (int)result);
    
    // set recording time
    SGSetMaximumRecordTime(sequenceGrabber, duration * 60 /* convert to ticks */);
    
//    unsigned int stops = 10;
//    while (stops > 0) {
      
      if( SGStartRecord(sequenceGrabber) != noErr )
        printf("Error: SGStartRecord failed.\n");
      
      // grab until sequence grabber terminates itself due to time limit
      while(SGIdle(sequenceGrabber) == noErr);
      
      result = SGStop(sequenceGrabber);
//    stops--;
//    sleep(1);
//  }
    if( result != noErr )
      printf("Error: SGStop failed (%d).\n", (int)result);
    result = CloseComponent(sequenceGrabber);
    if( result != noErr )
      printf("Error: CloseComponent failed (%d).\n", (int)result);
  }
  
  [pool release];
  
  return 0;
}
