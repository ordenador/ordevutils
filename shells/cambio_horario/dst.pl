#!/usr/bin/perl -w

# Display DST transition times

use English;
use strict;
use Time::Local;
use POSIX qw(strftime);
use Getopt::Std;

use constant VRSN => '[1.04]';
# 1.0  09/14/1998 acs
# 1.01 01/03/2001 acs changed '%e' strftime format specifier to '%d' because
#                     stupid Windows does not understand real strftime
# 1.02 09/10/2003 acs minor change; subtract 1900 from $year command-line arg;
#                     the code works w/o this change but this is more proper
# 1.03 09/12/2003 acs added -n option to print only the next time change
# 1.04 10/01/2003 acs added -d option to output days (integer) until next time
#                     change

use constant SECONDS_PER_DAY => (24 * 60 * 60);
use constant FALSE           => 0;
use constant TRUE            => 1;

use constant TWO_DATES_MODE  => 0;
use constant NEXT_MODE       => 1;
use constant DAYS_LEFT_MODE  => 2;

# ---------------------------------------------------------------

sub problem
{
  my $msg = $_[0];
  my $err = $_[1];

  printf STDERR ("%s: %s (%d).\n",$PROGRAM_NAME,$msg,$err);
  printf STDERR ("\n");
  return($err);
} # problem


sub usage
{
  printf STDERR
    ("\nUsage: %s [-y year | -n | -d] [-e] [-u]\n\n",
     $PROGRAM_NAME);
  printf STDERR
    ("  -y year  - determine time changes for year; by default, the current\n");
  printf STDERR
    ("             year is used.\n");
  printf STDERR
    ("  -n       - display only the next time change.\n");
  printf STDERR
    ("  -d       - display remaining days until next time change.\n");
  printf STDERR
    ("  -u       - print this usage message on stderr and exit.\n");
  printf STDERR
    ("  -e       - print the epoch seconds rather than the formatted times\n");
  printf STDERR
    ("             if used with -d, display integer rather than fractional\n");
  printf STDERR
    ("             days remaining until next time change.\n\n");
  printf STDERR
    ("If successful, %s returns a zero result and writes two lines on\n",
     $PROGRAM_NAME);
  printf STDERR
    ("stdout of this form:\n");
  printf STDERR
    ("    Sun Apr  5 01:59:59 CST 1998 --> Sun Apr  5 03:00:00 CDT 1998\n");
  printf STDERR
    ("    Sun Oct 25 01:59:59 CDT 1998 --> Sun Oct 25 01:00:00 CST 1998\n");
  printf STDERR
    ("                            OR (if using -e option)\n");
  printf STDERR
    ("    891763199 --> 891763200\n");
  printf STDERR
    ("    909298799 --> 909298800\n\n");
  printf STDERR
    ("These indicate the time displayed at the transition time and that\n");
  printf STDERR
    ("displayed 1 second later.\n\n");
  printf STDERR
    ("A non-zero result is returned if no TZ is known or no time transition\n");
  printf STDERR
    ("occurs.\n\n");
  printf STDERR
    ("Vrsn %s\n",VRSN);
  return(1);
} # usage


sub find_dst # returns the last epoch second $target_isdst is in effect
{
  use integer;

  my $lo = $_[0];
  my $max_hi = $_[1];
  my $initial_interval = $_[2];
  my $target_isdst = $_[3];
  my ($begin_seconds,$next_seconds) = (-1,-1);
  my $isdst = FALSE;

# advance by one interval until DST changes
  my $hi = $lo;
  my $fnd = FALSE;
  my $hi_knt = 0;
  while (!($fnd) && ($hi <= $max_hi) && ($hi_knt < 2))
    {
      $isdst = (localtime($hi))[8];
      if ($isdst != $target_isdst)
        {
          $fnd = TRUE;
        }
      else
        {
          $lo = $hi;
          $hi += $initial_interval;
          if ($hi > $max_hi)
            {
              $hi = $max_hi;
              ++$hi_knt;
            }
        }
    }
  if ($fnd) # now start looking within $interval
    {
      my $go_down = TRUE;
      my $tmp_seconds = $hi;
      my $interval = ($hi - $lo) / 2;
      while ($interval > 0)
        {
          if ($go_down)
            {
              $tmp_seconds = $hi - $interval;
              $isdst = (localtime($tmp_seconds))[8];
              if ($isdst == $target_isdst)
                {
                  $go_down = FALSE;
                  $lo = $tmp_seconds;
                }
              else
                {
                  $hi = $tmp_seconds;
                }
            }
          else
            {
              $tmp_seconds = $lo + $interval;
              $isdst = (localtime($tmp_seconds))[8];
              if ($isdst != $target_isdst)
                {
                  $go_down = TRUE;
                  $hi = $tmp_seconds;
                }
              else
                {
                  $lo = $tmp_seconds;
                }
            }
          $interval = ($hi - $lo) / 2;
        }
      if (((localtime($tmp_seconds))[8]) !=
          ((localtime($tmp_seconds + 1))[8]))
        {
          $begin_seconds = $tmp_seconds;
          $next_seconds = $tmp_seconds + 1;
        }
      else
        {
          $begin_seconds = $tmp_seconds - 1;
          $next_seconds = $tmp_seconds;
        }
    }
  return($begin_seconds,$next_seconds);
} # find_dst

my $year = -1;
my $cc = 0;
my $do_format = TRUE;
my $yr_arg_knt = 0;
my $mode = TWO_DATES_MODE;
my $now = 0;

our ($opt_y,$opt_n,$opt_d,$opt_u,$opt_e);

if (!getopts('y:ndue'))
  {
    $cc = 252;
    usage();
    exit($cc);
  }
if (defined($opt_y))
  {
    $year = $opt_y - 1900;
    ++$yr_arg_knt;
  }
if (defined($opt_n))
  {
    $mode = NEXT_MODE;
    ++$yr_arg_knt;
  }
if (defined($opt_d))
  {
    $mode = DAYS_LEFT_MODE;
    ++$yr_arg_knt;
  }
if (defined($opt_e))
  {
    $do_format = FALSE;
  }
if (defined($opt_u))
  {
    $cc = 251;
    usage();
    exit($cc);
  }
if ($yr_arg_knt > 1 && $cc == 0)
  {
    $cc = 255;
    problem("Only one -n or -y argument allowed",$cc);
  }
if ($year <= 0)
  {
    $now = time();
    $year = (localtime($now))[5];
  }
if ($cc != 0)
  {
    exit($cc);
  }
$cc = 2;

if (($mode == NEXT_MODE) || ($mode == DAYS_LEFT_MODE))
  {
    my $isdst_now = (localtime($now))[8];
    my $seconds_Dec31 = timelocal(59,59,23,31,11,$year + 1);
    my ($start1,$start2) = find_dst($now,$seconds_Dec31,
                                    SECONDS_PER_DAY,$isdst_now);
    if ($start1 > 0)
      {
        if ($mode == NEXT_MODE)
          {
            if ($do_format)
              {
                print strftime("%a %b %d %H:%M:%S %Z %Y",localtime($start1)),
                      " --> ",
                      strftime("%a %b %d %H:%M:%S %Z %Y",localtime($start2)),
                      "\n";
              }
            else
              {
                print $start1," --> ",$start2,"\n";
              }
          }
        else
          {
            if ($do_format)
              {
                printf("%.4f\n",(($start2 - $now) / SECONDS_PER_DAY));
              }
            else
              {
                printf("%d\n",int(($start2 - $now) / SECONDS_PER_DAY));
              }
          }
        $cc = 0;
      }
  }
else
  {
    my $seconds_Jan1 = timelocal(0,0,0,1,0,$year);
    my $isdst_Jan1 = (localtime($seconds_Jan1))[8];
    my $seconds_Dec31 = timelocal(59,59,23,31,11,$year);

    my ($start1,$start2) = find_dst($seconds_Jan1,$seconds_Dec31,
                                    SECONDS_PER_DAY,$isdst_Jan1);
    if ($start1 > 0)
      {
        $cc = 1;
        if ($do_format)
          {
            print strftime("%a %b %d %H:%M:%S %Z %Y",localtime($start1)),
                  " --> ",
                  strftime("%a %b %d %H:%M:%S %Z %Y",localtime($start2)),
                  "\n";
          }
        else
          {
            print $start1," --> ",$start2,"\n";
          }
        my ($end1,$end2) = find_dst($start2,$seconds_Dec31,
                                    SECONDS_PER_DAY,!($isdst_Jan1));
        if ($end1 > 0)
          {
            if ($do_format)
              {
                print strftime("%a %b %d %H:%M:%S %Z %Y",localtime($end1)),
                      " --> ",
                      strftime("%a %b %d %H:%M:%S %Z %Y",localtime($end2)),
                      "\n";
              }
            else
              {
                print $end1," --> ",$end2,"\n";
              }
            $cc = 0;
          }
      }
  }
exit($cc);
