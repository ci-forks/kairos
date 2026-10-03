import sqlite3, json, sys
db=sys.argv[1]
c=sqlite3.connect(db)
now='2026-10-03 12:00:00+00:00'
hier=json.dumps({"sysext":["/opt","/usr/local/lib/vendor"],"confext":["/etc/vendor-site"]})
cols="id,name,saved,phase,message,base_image,kairos_version,model,iso,cloud_image,netboot,f_ip_s,trusted_boot,arch,variant,insecure,raw_disk,tar,gce,vhd,maas,uki,kairos_init_image,auto_install,register_aurora_boot,dockerfile,hadron_base,hadron_firmware,hadron_layers,hadron_extra,cloud_config,kubernetes_distro,kubernetes_version,target_group_id,container_image,overlay_rootfs,artifact_files,extension_hierarchies,logs,upload_token,created_at,updated_at,extensions,extensions_catalogs"
def art(id,name,base,hb):
    vals=[id,name,1,'Ready','',base,'v4.3.0','generic',1,0,0,0,0,'amd64','core',0,0,0,0,0,0,0,'',1,0,'',hb,'[]','[]','','#cloud-config\n','','','','','','[]',hier,'','',now,now,'[]','[]']
    c.execute(f"insert into artifact_records({cols}) values({','.join('?'*len(vals))})",vals)
art('qa-plain-0001','qa-plain-source','ubuntu:24.04','')
art('qa-hadron-0001','qa-hadron-source','ghcr.io/kairos-io/hadron:v0.5.3','ghcr.io/kairos-io/hadron:v0.5.3')
ecols="id,name,type,phase,message,arch,version,source_mode,source_artifact_id,source_image,dockerfile,extra_steps,signing_key_set_id,hierarchies,service_reload,container_image,raw_filename,download_token,logs,created_at,updated_at"
for i,(n,t,v) in enumerate([('qa-monitoring','sysext','1.2.0'),('qa-site-config','confext','0.1.0'),('qa-unbundled','sysext','9.9.9')]):
    vals=[f'qa-ext-{i}',n,t,'Ready','','amd64',v,'image','','busybox','','','','[]',0,'',f'{n}.{t}.raw','','',now,now]
    c.execute(f"insert into extension_records({ecols}) values({','.join('?'*len(vals))})",vals)
c.commit()
