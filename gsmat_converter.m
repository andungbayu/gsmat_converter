function gsmat_converter(startdate,enddate,minlon,maxlon,minlat,maxlat)

% contoh definisi pembacaan waktu
% startdate=[2019,1,1];  % tahun, bulan, tanggal
% enddate=[2019,1,4];    % tahun, bulan, tanggal

% program start definition
interval_hari=1;

% definisi direktori file
file_dir='';
copy_dir='';
extract_dir='';  

% define boundary area
xl=minlon;
xr=maxlon;
yb=minlat;
yt=maxlat;

% Lat/lon grids and other info of GSMAP
xdim=3600;
ydim=1200;
rs_lon=360/xdim;
rs_lat=120/ydim;
Lon=0:rs_lon:360;
Lat=60:-rs_lat:-60;

% default data reading
ndv=0; % no-data value
scf=1; % Scale factor

%---------------------------mulai analisis--------------------------

% menyusun array waktu untuk membuka file
t_start=datenum(startdate);
t_end=datenum(enddate);

% definisi nilai awal loop
t_loop=t_start; % info waktu data yang akan dibuka (tgl bulan,tahun)

% memulai proses loop untuk membuka setiap file
while t_loop<=t_end,

	% menyusun nama file
	str_tanggal=datestr(t_loop,'yyyymmdd'); % tahun (4 digit)
	
	% skip file jika data sudah tersedia
	outputfile=[copy_dir,'gsmap_',str_tanggal,'.mat'];
	if ((exist(outputfile))>0),
	    disp([outputfile,' telah diproses'])
	    t_loop=t_loop+(interval_hari);
		continue; 
	end
	
  % ------------------- ekstrak file --------------------------------
	% menyusun nama file
	filename_gz=['gsmap_gauge.',str_tanggal,'*'];
	gzfilefind=[file_dir,filename_gz];
	
	% cek file eksis
	if (isempty(dir(gzfilefind))==1),continue;end
	gzfileinfo=struct2cell(dir(gzfilefind));
  gzfilechar=char(gzfileinfo(1,1));
	
	% menyiapkan copy file
	filename_ori=gzfilechar(1:length(gzfilechar)-3);  % menghapus.gz
	extractfile=[extract_dir,filename_ori];
	copyfilegz=[copy_dir,filename_ori,'.copy.gz'];
	gzfile=[file_dir,gzfilechar];
	
	% skip loop apabila file tidak ditemukan
	if ((exist(gzfile))==0),
	    disp([gzfile,' tidak ditemukan'])
	    t_loop=t_loop+(interval_hari);
		  continue; 
	end
	
	% notifikasi status apabila file ditemukan
	disp(['memproses ',gzfile]);
	
	% copy untuk unzip data
	disp(['mulai extract data ke ',extractfile]);
	copyfile(gzfile,copyfilegz);
  
  % skip loop apabila file tidak ditemukan
	if ((exist(gzfile))==0),
	    disp([gzfile,' tidak ditemukan'])
	    t_loop=t_loop+(interval_hari);
		  continue; 
	end
	gunzip(gzfile,extract_dir);
  
  % kembalikan data
  if ((exist(copyfilegz))==0),
	    disp([copyfilegz,' move file gagal'])
	    t_loop=t_loop+(interval_hari);
		  continue; 
	end
	disp(['kembalikan gz data ke ',gzfile]);
	movefile(copyfilegz,gzfile);
	
	% -------------------proses data ------------------------------
	if xl(1)<0 % Convert longitude to the range of [0 360];
	  xl(1)=xl(1)+360;
	end
	if xr(1)<0
	  xr(1)=xr(1)+360;
	end

	% find index location
	cl=find(xl(1)-Lon>=0,1,'last'); % left column
	cr=find(xr(1)-Lon<=0,1,'first')-1; % right column
	rt=find(yt(1)-Lat<=0,1,'last'); % top row
	rb=find(yb(1)-Lat>=0,1,'first')-1; % bottom row

	% define number of row
	nr=length(rt:rb); % number of row
	nc=length(cl:cr); % number of column
	xll=(cl-1)*rs_lon; % longitude of lower left corner
	yll=60-rb*rs_lat; % latitude of lower left corner

	% read file
	fid=fopen(extractfile,'r'); % read
	raw=fread(fid,[xdim ydim],'real*4','l'); % double or uint16
	fclose(fid);
	delete(extractfile);

	% transpose data and crop
    raw(raw<ndv)=NaN;
	p=raw(cl:cr,rt:rb);
	p=double(transpose(p)/scf);
	lat=Lat(rt:rb);
	lon=Lon(cl:cr);
	
	% simpan file
	outputfile=[copy_dir,'gsmap_',str_tanggal,'.mat'];
	save(outputfile,'p','lat','lon');
  
	% tambahkan waktu untuk file berikutnya
    t_loop=t_loop+(interval_hari);

end