import commands
import glob
import nose
import os
import re
import sys
import shutil
import tempfile

try:
    import xml.etree.ElementTree as ET  # python >= 2.5
except ImportError:
    import elementtree.ElementTree as ET  # python <= 2.4; needs ElementTree.

from nose.tools import with_setup
from os.path import join as pathjoin

import package

try:
    all
except NameError:
    def all(xs):
        return [x for x in xs if not x] == []



WORKDIR = None
BUILD_SRCDIR = None
BUILD_DATADIR = None

DOMNAME = 'test-domain-1'
DOMXML = DOMNAME + '.xml'

NORM_IMG_1 = 'test-domain-1-disk-1.qcow2'
DELTA_IMG_1 = 'test-domain-1-disk-2.qcow2'
DELTA_IMG_1_BASE = 'test-domain-1-disk-2-base.qcow2'

IMGS_IN_DOMXML = [pathjoin('@TESTDIR@', i) for i in (NORM_IMG_1, DELTA_IMG_1)]



def create_image(image_dir, image_name):
    os.system("cd %s && qemu-img create -f qcow2 %s 1M 2>&1 >/dev/null" \
        % (image_dir, image_name))


def create_delta_image(image_dir, base_image_name, image_name):
    if not os.path.exists(pathjoin(image_dir, base_image_name)):
        create_image(image_dir, base_image_name)

    os.system("cd %s && qemu-img create -f qcow2 -b %s %s 2>&1 >/dev/null" \
        % (image_dir, base_image_name, image_name))


def copytree(srcdir, dstdir):
    """cp -r srcdir dstdir
    """
    assert srcdir != dstdir, "src = %s, dst = %s" % (srcdir, dstdir)

    os.system('cp -r %s %s' % (srcdir, dstdir))


def copy_build_data(dstdir):
    shutil.copy2('../../rpm.mk', dstdir)
    copytree('../../m4/', dstdir)
    copytree('../../data/package/', dstdir)
    copytree('../../data/repackage/', dstdir)


def prune_dir(dir):
    if not os.path.exists(dir):
        return  # Nothing to do.

    for x in glob.glob(pathjoin(dir, '*')):
        if os.path.isdir(x):
            prune_dir(x)
        else:
            os.remove(x)

    if os.path.exists(dir):
        os.removedirs(dir)


def setup():
    global WORKDIR

    WORKDIR = tempfile.mkdtemp(dir=os.curdir)


def image_setup():
    global WORKDIR, BUILD_SRCDIR, DELTA_IMG_1, DELTA_IMG_1_BASE

    setup()

    BUILD_SRCDIR = pathjoin(WORKDIR, 'original_images')
    os.mkdir(BUILD_SRCDIR)
    (_ret, _out) = commands.getstatusoutput("chcon -R -t virt_image_t %s" % BUILD_SRCDIR)

    create_image(BUILD_SRCDIR, NORM_IMG_1)
    create_delta_image(BUILD_SRCDIR, DELTA_IMG_1_BASE, DELTA_IMG_1)

    xmlcontent = open(DOMXML).read().replace('@TESTDIR@', BUILD_SRCDIR)
    open(pathjoin(BUILD_SRCDIR, DOMXML),'w').write(xmlcontent)


def build_setup():
    global WORKDIR, BUILD_SRCDIR, BUILD_DATADIR, DOMNAME, DOMXML

    image_setup()

    BUILD_DATADIR = pathjoin(WORKDIR, 'build_data')
    os.mkdir(BUILD_DATADIR)

    copy_build_data(BUILD_DATADIR)


def teardown():
    global WORKDIR

    prune_dir(WORKDIR)


# tests:
def test_run():
    cmds = 'ls /proc/sys/fs/file-nr'

    (ret, out) = package.run(cmds)

    assert ret == 0, "return code = %d" % ret
    assert out == cmds.split()[1]


def test_package_name():
    global DOMNAME

    assert "%s-%s-%s" % (package.RPMNAME_PREFIX, DOMNAME, package.RPMNAME_SUFFIX) \
        == package.package_name(DOMNAME, package.RPMNAME_PREFIX, package.RPMNAME_SUFFIX)


def test_is_libvirtd_running():
    is_root = False

    if is_root:
        package.run("/etc/rc.d/init.d/libvirtd restart")
        assert package.is_libvirtd_running()

        package.run("/etc/rc.d/init.d/libvirtd stop")
        assert not package.is_libvirtd_running()


## TODO:
def test_get_domain_xml():
    pass

def test_domain_status():
    pass


@with_setup(setup, teardown)
def test_substfile():
    global WORKDIR

    src = '%s/subst_src_0' % WORKDIR
    dst = src + '.new'

    open(src, 'w').write('aaa=bbb')
    package.substfile(src, dst, {'bbb': 'ccc'})

    assert re.match('aaa=bbb', open(src).read()) is not None
    assert re.match('aaa=bbb', open(dst).read()) is None
    assert re.match('aaa=ccc', open(dst).read()) is not None


@with_setup(setup, teardown)
def test_createdir():
    global WORKDIR

    dir = pathjoin(WORKDIR, 'test-1')
    package.createdir(dir)

    assert os.path.isdir(dir)

    os.rmdir(dir)


def test_parse_domain_xml():
    global DOMNAME, DOMXML, IMGS_IN_DOMXML

    dominfo = package.parse_domain_xml(open(DOMXML).read())
    arch = 'i686'
    images = sorted(IMGS_IN_DOMXML)

    assert DOMNAME == dominfo['name']
    assert arch == dominfo['arch']
    assert all((x == y for x, y in zip(images, dominfo['images'])))


@with_setup(image_setup, teardown)
def test_base_image_path_normal_image():
    global BUILD_SRCDIR, NORM_IMG_1

    ipath = pathjoin(BUILD_SRCDIR, NORM_IMG_1)
    bpath = package.base_image_path(ipath)

    assert bpath == "", "image = '%s', base = '%s'" % (ipath, bpath)


@with_setup(image_setup, teardown)
def test_base_image_path_delta_image():
    global BUILD_SRCDIR, DELTA_IMG_1_BASE, DELTA_IMG_1 

    ipath = pathjoin(BUILD_SRCDIR, DELTA_IMG_1)
    bpath = package.base_image_path(ipath)

    assert bpath != "", "image = '%s', base = '%s'" % (ipath, bpath)
    assert bpath == pathjoin(BUILD_SRCDIR, DELTA_IMG_1_BASE), \
        "image = '%s', base = '%s'" % (ipath, bpath)


@with_setup(image_setup, teardown)
def test_domain_image_paths():
    global BUILD_SRCDIR, DOMXML, IMGS_IN_DOMXML, DELTA_IMG_1_BASE

    domxml_content = open(pathjoin(BUILD_SRCDIR, DOMXML)).read()
    ref_images = sorted(
        [p.replace('@TESTDIR@', BUILD_SRCDIR) for p in IMGS_IN_DOMXML] + \
            [pathjoin(BUILD_SRCDIR, DELTA_IMG_1_BASE)]
    )

    images = sorted(package.domain_image_paths(domxml_content))

    assert all((x == y for x, y in zip(images, ref_images))), \
        "images = '%s', ref_images = '%s'" % (str(images),str(ref_images))


@with_setup(setup, teardown)
def test_copyfile():
    global WORKDIR, DOMXML

    copyto = pathjoin(WORKDIR, DOMXML + '.copy')
    package.copyfile(DOMXML, copyto)

    assert os.path.exists(copyto)


@with_setup(build_setup, teardown)
def test_do_repackage_setup():
    global WORKDIR, BUILD_SRCDIR, BUILD_DATADIR, DOMXML, DOMNAME

    builddir = package.make_builddir(WORKDIR, DOMNAME)
    package.do_repackage_setup(BUILD_DATADIR, DOMNAME, 'minimal', pathjoin(BUILD_SRCDIR, DOMXML), builddir)


@with_setup(build_setup, teardown)
def test_do_build__repackage():
    global WORKDIR, BUILD_SRCDIR, BUILD_DATADIR, DOMXML, DOMNAME

    builddir = package.make_builddir(WORKDIR, DOMNAME)
    package.do_repackage_setup(BUILD_DATADIR, DOMNAME, 'minimal', pathjoin(BUILD_SRCDIR, DOMXML), builddir)
    package.do_build(DOMNAME, builddir)


#@with_setup(build_setup, teardown)
@with_setup(build_setup)
def test_do_package__repackage():
    global WORKDIR, BUILD_SRCDIR, BUILD_DATADIR, DOMXML, DOMNAME

    builddir = package.make_builddir(WORKDIR, DOMNAME)
    package.do_repackage_setup(BUILD_DATADIR, DOMNAME, 'minimal', pathjoin(BUILD_SRCDIR, DOMXML), builddir)
    package.do_build(DOMNAME, builddir)
    package.do_package(DOMNAME, builddir)


@with_setup(build_setup, teardown)
def test_do_package_setup():
    global WORKDIR, BUILD_SRCDIR, BUILD_DATADIR, DOMXML, DOMNAME

    builddir = package.make_builddir(WORKDIR, DOMNAME)
    package.do_package_setup(BUILD_DATADIR, DOMNAME, 'minimal', builddir)


if __name__ == '__main__':
    nose.runmodule()

# vim: set sw=4 ts=4 et: