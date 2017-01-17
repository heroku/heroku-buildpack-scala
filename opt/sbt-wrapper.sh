case $(ulimit -u) in
32768) # PX Dyno
  maxSbtHeap=5220
  ;;
*)     # 2X Dyno
  maxSbtHeap=768
  ;;
esac

sbtHome="${SBT_HOME:-"$HOME"}"

sbt-extras ${SBT_EXTRAS_OPTS} \
  -J-Xmx${maxSbtHeap}M \
  -J-Xms${maxSbtHeap}M \
  -J-XX:+UseCompressedOops \
  -sbt-dir $sbtHome \
  -ivy $sbtHome/.ivy2 \
  -sbt-launch-dir $SBT_HOME/launchers \
  -Duser.home=$sbtHome \
  -Divy.default.ivy.user.dir=$sbtHome/.ivy2 \
  -Dfile.encoding=UTF8 \
  -Dsbt.global.base=$sbtHome \
  -Dsbt.log.noformat=true \
  -no-colors $([[ "$@" != *-no-batch* ]] && echo "-batch") \
  "$@"
