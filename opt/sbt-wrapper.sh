case $(ulimit -u) in
32768) # PX Dyno
  maxSbtHeap=5220
  ;;
*)     # 2X Dyno
  maxSbtHeap=768
  ;;
esac

sbt-extras ${SBT_EXTRAS_OPTS} \
  -J-Xmx${maxSbtHeap}M \
  -J-Xms${maxSbtHeap}M \
  -J-XX:+UseCompressedOops \
  -sbt-dir $SBT_HOME \
  -ivy $SBT_HOME/.ivy2 \
  -sbt-launch-dir $SBT_HOME/launchers \
  -Duser.home=$SBT_HOME \
  -Divy.default.ivy.user.dir=$SBT_HOME/.ivy2 \
  -Dfile.encoding=UTF8 \
  -Dsbt.global.base=$SBT_HOME \
  -Dsbt.log.noformat=true \
  -no-colors -batch \
  "$@"
