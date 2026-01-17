# Duduski's Scene
# https://blog.csdn.net/minwenping/article/details/73823414

cmd_base="service call SurfaceFlinger 1015 i32 1  "
mat4_default() {
  values='
  1 0 0 0
  0 1 0 0
  0 0 1 0
  0 0 0 1'
  cmd="$cmd_base"
  for i in $values; do
    cmd="$cmd f $i"
  done
  $cmd
}

# mat4 [N]
mat4() {
  values="
  $1 0 0 0
  0 $1 0 0
  0 0 $1 0
  0 0 0 $1"
  cmd="$cmd_base"
  for i in $values; do
    cmd="$cmd f $i"
  done
  $cmd
}

# mat4_rgb [R] [G] [B]
mat4_rgb() {
  values="
  $1 0 0 0
  0 $2 0 0
  0 0 $3 0
  0 0 0 1"
  cmd="$cmd_base"
  for i in $values; do
    cmd="$cmd f $i"
  done
  $cmd
}

# mat4_rgba [R] [G] [B] [A]
mat4_rgba() {
  values="
  $1 0 0 0
  0 $2 0 0
  0 0 $3 0
  $4 $4 $4 0"
  cmd="$cmd_base"
  for i in $values; do
    cmd="$cmd f $i"
  done
  $cmd
}

# mat4_aaa [rA] [gA] [bA]
mat4_aaa() {
  values="
  $1 0 0 0
  0 $2 0 0
  0 0 $3 0
  $4 $4 $4 0"
  cmd="$cmd_base"
  for i in $values; do
    cmd="$cmd f $i"
  done
  $cmd
}

$1 $2 $3 $4 $5 $6
