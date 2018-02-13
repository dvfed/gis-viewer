{*********************************************************************
  Geos_c.pas

  PAS Unit interface for GEOS library (geos_c.h)

  Adapted by: Dmitriy Fedorov <dvfedorov@mail.ru>
  2010 - 2015

  Based on the sources automatically converted by H2Pas utility.

***********************************************************************
*
*
* C-Wrapper for GEOS library
*
* Copyright (C) 2010 2011 Sandro Santilli <strk@keybit.net>
* Copyright (C) 2005 Refractions Research Inc.
*
* This is free software; you can redistribute and/or modify it under
* the terms of the GNU Lesser General Public Licence as published
* by the Free Software Foundation.
* See the COPYING file for more information.
*
* Author: Sandro Santilli <strk@keybit.net>
*
***********************************************************************
*
* GENERAL NOTES:
*
*	- Remember to call initGEOS() before any use of this library's
*	  functions, and call finishGEOS() when done.
*
*	- Currently you have to explicitly GEOSGeom_destroy() all
*	  GEOSGeom objects to avoid memory leaks, and to GEOSFree()
*	  all returned char * (unless const).
*
*	- Functions ending with _r are thread safe; see details in RFC 3
*	  http://trac.osgeo.org/geos/wiki/RFC3
*
********************************************************************** }
unit geos_c;

interface

const
  External_library = 'geos_c.dll';

Type
  GEOSChar = byte;
  GEOSUChar = byte;
  GEOSInt = Integer;
  GEOSUInt = Integer;
  GEOSsize_t = Integer;
  GEOSDouble = double;

  PGEOSChar = ^GEOSChar;
  PPGEOSChar = array of PGEOSChar;
  PGEOSUChar = ^GEOSUChar;
  PGEOSInt = ^GEOSInt;
  PGEOSUInt = ^GEOSUInt;
  PGEOSsize_t = ^GEOSsize_t;
  PGEOSDouble = ^GEOSDouble;

  { ***********************************************************************
    *
    * Version
    *
    ********************************************************************** }
const
  GEOS_CAPI_VERSION_MAJOR = 1;
  GEOS_CAPI_VERSION_MINOR = 8;
  GEOS_CAPI_VERSION_PATCH = 2;
  GEOS_CAPI_VERSION = '3.4.2-CAPI-1.8.2';
  GEOS_VERSION_MAJOR = 3;
  GEOS_VERSION_MINOR = 4;
  GEOS_VERSION_PATCH = 2;
  GEOS_VERSION = '3.4.2';
  GEOS_JTS_PORT = '1.12.0';
  GEOS_CAPI_FIRST_INTERFACE = GEOS_CAPI_VERSION_MAJOR;
  GEOS_CAPI_LAST_INTERFACE = GEOS_CAPI_VERSION_MAJOR + GEOS_CAPI_VERSION_MINOR;

  { ***********************************************************************
    *
    * (Abstract) type definitions
    *
    *********************************************************************** }
type
  GEOSBufCapStyles = (GEOSBUF_CAP_ROUND = 1, GEOSBUF_CAP_FLAT = 2,
    GEOSBUF_CAP_SQUARE = 3);

  GEOSBufJoinStyles = (GEOSBUF_JOIN_ROUND = 1, GEOSBUF_JOIN_MITRE = 2,
    GEOSBUF_JOIN_BEVEL = 3);

  { const }
type
  GEOSMessageHandler = procedure(fmt: PGEOSChar; args: array of const); cdecl;

  GEOSGeometry         = record end;
  GEOSPreparedGeometry = record end;
  GEOSCoordSequence    = record end;
  GEOSSTRtree =  record end;
  GEOSBufferParams = record end;

  GEOSWKTReader = record end;
  GEOSWKTWriter = record end;
  GEOSWKBReader = record end;
  GEOSWKBWriter = record end;

  { Supported geometry types
    * This was renamed from GEOSGeomTypeId in GEOS 2.2.X, which might
    * break compatibility, this issue is still under investigation.
  }
  GEOSGeomTypes = (GEOS_POINT, GEOS_LINESTRING, GEOS_LINEARRING, GEOS_POLYGON,
    GEOS_MULTIPOINT, GEOS_MULTILINESTRING, GEOS_MULTIPOLYGON,
    GEOS_GEOMETRYCOLLECTION);

  { Byte oders exposed via the c api }
  { Big Endian }
  { Little Endian }
  GEOSByteOrders = (GEOS_WKB_XDR = 0, GEOS_WKB_NDR = 1);

  GEOSContextHandle_HS = record end;
  PGEOSContextHandle_t = ^GEOSContextHandle_t;
  GEOSContextHandle_t = GEOSContextHandle_HS;

  GEOSQueryCallback = procedure (item: pointer; userdata: pointer); cdecl;
  GEOSInterruptCallback = procedure; cdecl;

Type
  PGEOSBufCapStyles = ^GEOSBufCapStyles;
  PGEOSBufferParams = ^GEOSBufferParams;
  PGEOSBufJoinStyles = ^GEOSBufJoinStyles;
  PGEOSByteOrders = ^GEOSByteOrders;
//  PGEOSContextHandle_t = ^GEOSContextHandle_t;
//  PGEOSCoordSeq = ^GEOSCoordSeq;
  PGEOSCoordSequence = ^GEOSCoordSequence;
//  PGEOSGeom = ^GEOSGeom;
  PGEOSGeometry = ^GEOSGeometry;
  PPGEOSGeometry = array of PGEOSGeometry;
  PGEOSGeomTypes = ^GEOSGeomTypes;
  PGEOSInterruptCallback = ^GEOSInterruptCallback;
  PGEOSPreparedGeometry = ^GEOSPreparedGeometry;
//  PGEOSRelateBoundaryNodeRules = ^GEOSRelateBoundaryNodeRules;
  PGEOSSTRtree = ^GEOSSTRtree;
//  PGEOSValidFlags = ^GEOSValidFlags;
  PGEOSWKBReader = ^GEOSWKBReader;
  PGEOSWKBWriter = ^GEOSWKBWriter;
  PGEOSWKTReader = ^GEOSWKTReader;
  PGEOSWKTWriter = ^GEOSWKTWriter;

  { ***********************************************************************
    *
    * Initialization, cleanup, version
    *
    ********************************************************************** }
procedure initGEOS(notice_function: GEOSMessageHandler;
  error_function: GEOSMessageHandler); cdecl;
  external External_library name 'initGEOS';

procedure finishGEOS; cdecl; external External_library name 'finishGEOS';

{
  * Register an interruption checking callback
  *
  * The callback will be invoked _before_ checking for
  * interruption, so can be used to request it.
}

//type

function GEOS_interruptRegisterCallback(cb: PGEOSInterruptCallback)
  : PGEOSInterruptCallback; cdecl;
  external External_library name 'GEOS_interruptRegisterCallback';

{ Request safe interruption of operations }
procedure GEOS_interruptRequest; cdecl;
  external External_library name 'GEOS_interruptRequest';

{ Cancel a pending interruption request }
procedure GEOS_interruptCancel; cdecl;
  external External_library name 'GEOS_interruptCancel';

function initGEOS_r(notice_function: GEOSMessageHandler;
  error_function: GEOSMessageHandler): GEOSContextHandle_t; cdecl;
  external External_library name 'initGEOS_r';

procedure finishGEOS_r(handle: GEOSContextHandle_t); cdecl;
  external External_library name 'finishGEOS_r';

function GEOSContext_setNoticeHandler_r(extHandle: GEOSContextHandle_t;
  nf: GEOSMessageHandler): GEOSMessageHandler; cdecl;
  external External_library name 'GEOSContext_setNoticeHandler_r';

function GEOSContext_setErrorHandler_r(extHandle: GEOSContextHandle_t;
  ef: GEOSMessageHandler): GEOSMessageHandler; cdecl;
  external External_library name 'GEOSContext_setErrorHandler_r';

{ const } function GEOSversion: PGEOSChar; cdecl;
  external External_library name 'GEOSversion';

{ ***********************************************************************
  *
  * NOTE - These functions are DEPRECATED.  Please use the new Reader and
  * writer APIS!
  *
  ********************************************************************** }
{ const } function GEOSGeomFromWKT(wkt: PGEOSChar): PGEOSGeometry; cdecl;
  external External_library name 'GEOSGeomFromWKT';

{ const } function GEOSGeomToWKT(g: PGEOSGeometry): PGEOSChar; cdecl;
  external External_library name 'GEOSGeomToWKT';

{ const } function GEOSGeomFromWKT_r(handle: GEOSContextHandle_t;
  wkt: PGEOSChar): PGEOSGeometry; cdecl;
  external External_library name 'GEOSGeomFromWKT_r';

{ const } function GEOSGeomToWKT_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry): PGEOSChar; cdecl;
  external External_library name 'GEOSGeomToWKT_r';

{
  * Specify whether output WKB should be 2d or 3d.
  * Return previously set number of dimensions.
}
function GEOS_getWKBOutputDims: GEOSInt; cdecl;
  external External_library name 'GEOS_getWKBOutputDims';

function GEOS_setWKBOutputDims(newDims: GEOSInt): GEOSInt; cdecl;
  external External_library name 'GEOS_setWKBOutputDims';

function GEOS_getWKBOutputDims_r(handle: GEOSContextHandle_t): GEOSInt; cdecl;
  external External_library name 'GEOS_getWKBOutputDims_r';

function GEOS_setWKBOutputDims_r(handle: GEOSContextHandle_t; newDims: GEOSInt)
  : GEOSInt; cdecl; external External_library name 'GEOS_setWKBOutputDims_r';

{
  * Specify whether the WKB byte order is big or little endian.
  * The return value is the previous byte order.
}
function GEOS_getWKBByteOrder: GEOSInt; cdecl;
  external External_library name 'GEOS_getWKBByteOrder';

function GEOS_setWKBByteOrder(byteOrder: GEOSInt): GEOSInt; cdecl;
  external External_library name 'GEOS_setWKBByteOrder';

{ const } function GEOSGeomFromWKB_buf(wkb: PGEOSUChar; size: GEOSsize_t)
  : PGEOSGeometry; cdecl; external External_library name 'GEOSGeomFromWKB_buf';

{ const } function GEOSGeomToWKB_buf(g: PGEOSGeometry; size: PGEOSsize_t)
  : PGEOSUChar; cdecl; external External_library name 'GEOSGeomToWKB_buf';

{ const } function GEOSGeomFromHEX_buf(hex: PGEOSUChar; size: GEOSsize_t)
  : PGEOSGeometry; cdecl; external External_library name 'GEOSGeomFromHEX_buf';

{ const } function GEOSGeomToHEX_buf(g: PGEOSGeometry; size: PGEOSsize_t)
  : PGEOSUChar; cdecl; external External_library name 'GEOSGeomToHEX_buf';

function GEOS_getWKBByteOrder_r(handle: GEOSContextHandle_t): GEOSInt; cdecl;
  external External_library name 'GEOS_getWKBByteOrder_r';

function GEOS_setWKBByteOrder_r(handle: GEOSContextHandle_t; byteOrder: GEOSInt)
  : GEOSInt; cdecl; external External_library name 'GEOS_setWKBByteOrder_r';

{ const } function GEOSGeomFromWKB_buf_r(handle: GEOSContextHandle_t;
  wkb: PGEOSUChar; size: GEOSsize_t): PGEOSGeometry; cdecl;
  external External_library name 'GEOSGeomFromWKB_buf_r';

{ const } function GEOSGeomToWKB_buf_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry; size: PGEOSsize_t): PGEOSUChar; cdecl;
  external External_library name 'GEOSGeomToWKB_buf_r';

{ const } function GEOSGeomFromHEX_buf_r(handle: GEOSContextHandle_t;
  hex: PGEOSUChar; size: GEOSsize_t): PGEOSGeometry; cdecl;
  external External_library name 'GEOSGeomFromHEX_buf_r';

{ const } function GEOSGeomToHEX_buf_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry; size: PGEOSsize_t): PGEOSUChar; cdecl;
  external External_library name 'GEOSGeomToHEX_buf_r';

{ ***********************************************************************
  *
  * Coordinate Sequence functions
  *
  ********************************************************************** }
{
  * Create a Coordinate sequence with ``size'' coordinates
  * of ``dims'' dimensions.
  * Return NULL on exception.
}
function GEOSCoordSeq_create(size: GEOSUInt; dims: GEOSUInt)
  : PGEOSCoordSequence; cdecl;
  external External_library name 'GEOSCoordSeq_create';

function GEOSCoordSeq_create_r(handle: GEOSContextHandle_t; size: GEOSUInt;
  dims: GEOSUInt): PGEOSCoordSequence; cdecl;
  external External_library name 'GEOSCoordSeq_create_r';

{
  * Clone a Coordinate Sequence.
  * Return NULL on exception.
}
{ const } function GEOSCoordSeq_clone(s: PGEOSCoordSequence)
  : PGEOSCoordSequence; cdecl;
  external External_library name 'GEOSCoordSeq_clone';

{ const } function GEOSCoordSeq_clone_r(handle: GEOSContextHandle_t;
  s: PGEOSCoordSequence): PGEOSCoordSequence; cdecl;
  external External_library name 'GEOSCoordSeq_clone_r';

{
  * Destroy a Coordinate Sequence.
}
procedure GEOSCoordSeq_destroy(s: PGEOSCoordSequence); cdecl;
  external External_library name 'GEOSCoordSeq_destroy';

procedure GEOSCoordSeq_destroy_r(handle: GEOSContextHandle_t;
  s: PGEOSCoordSequence); cdecl;
  external External_library name 'GEOSCoordSeq_destroy_r';

{
  * Set ordinate values in a Coordinate Sequence.
  * Return 0 on exception.
}
function GEOSCoordSeq_setX(s: PGEOSCoordSequence; idx: GEOSUInt;
  val: GEOSDouble): GEOSInt; cdecl;
  external External_library name 'GEOSCoordSeq_setX';

function GEOSCoordSeq_setY(s: PGEOSCoordSequence; idx: GEOSUInt;
  val: GEOSDouble): GEOSInt; cdecl;
  external External_library name 'GEOSCoordSeq_setY';

function GEOSCoordSeq_setZ(s: PGEOSCoordSequence; idx: GEOSUInt;
  val: GEOSDouble): GEOSInt; cdecl;
  external External_library name 'GEOSCoordSeq_setZ';

function GEOSCoordSeq_setOrdinate(s: PGEOSCoordSequence; idx: GEOSUInt;
  dim: GEOSUInt; val: GEOSDouble): GEOSInt; cdecl;
  external External_library name 'GEOSCoordSeq_setOrdinate';

function GEOSCoordSeq_setX_r(handle: GEOSContextHandle_t; s: PGEOSCoordSequence;
  idx: GEOSUInt; val: GEOSDouble): GEOSInt; cdecl;
  external External_library name 'GEOSCoordSeq_setX_r';

function GEOSCoordSeq_setY_r(handle: GEOSContextHandle_t; s: PGEOSCoordSequence;
  idx: GEOSUInt; val: GEOSDouble): GEOSInt; cdecl;
  external External_library name 'GEOSCoordSeq_setY_r';

function GEOSCoordSeq_setZ_r(handle: GEOSContextHandle_t; s: PGEOSCoordSequence;
  idx: GEOSUInt; val: GEOSDouble): GEOSInt; cdecl;
  external External_library name 'GEOSCoordSeq_setZ_r';

function GEOSCoordSeq_setOrdinate_r(handle: GEOSContextHandle_t;
  s: PGEOSCoordSequence; idx: GEOSUInt; dim: GEOSUInt; val: GEOSDouble)
  : GEOSInt; cdecl; external External_library name 'GEOSCoordSeq_setOrdinate_r';

{
  * Get ordinate values from a Coordinate Sequence.
  * Return 0 on exception.
}
{ const } function GEOSCoordSeq_getX(s: PGEOSCoordSequence; idx: GEOSUInt;
  val: PGEOSDouble): GEOSInt; cdecl;
  external External_library name 'GEOSCoordSeq_getX';

{ const } function GEOSCoordSeq_getY(s: PGEOSCoordSequence; idx: GEOSUInt;
  val: PGEOSDouble): GEOSInt; cdecl;
  external External_library name 'GEOSCoordSeq_getY';

{ const } function GEOSCoordSeq_getZ(s: PGEOSCoordSequence; idx: GEOSUInt;
  val: PGEOSDouble): GEOSInt; cdecl;
  external External_library name 'GEOSCoordSeq_getZ';

{ const } function GEOSCoordSeq_getOrdinate(s: PGEOSCoordSequence;
  idx: GEOSUInt; dim: GEOSUInt; val: PGEOSDouble): GEOSInt; cdecl;
  external External_library name 'GEOSCoordSeq_getOrdinate';

{ const } function GEOSCoordSeq_getX_r(handle: GEOSContextHandle_t;
  s: PGEOSCoordSequence; idx: GEOSUInt; val: PGEOSDouble): GEOSInt; cdecl;
  external External_library name 'GEOSCoordSeq_getX_r';

{ const } function GEOSCoordSeq_getY_r(handle: GEOSContextHandle_t;
  s: PGEOSCoordSequence; idx: GEOSUInt; val: PGEOSDouble): GEOSInt; cdecl;
  external External_library name 'GEOSCoordSeq_getY_r';

{ const } function GEOSCoordSeq_getZ_r(handle: GEOSContextHandle_t;
  s: PGEOSCoordSequence; idx: GEOSUInt; val: PGEOSDouble): GEOSInt; cdecl;
  external External_library name 'GEOSCoordSeq_getZ_r';

{ const } function GEOSCoordSeq_getOrdinate_r(handle: GEOSContextHandle_t;
  s: PGEOSCoordSequence; idx: GEOSUInt; dim: GEOSUInt; val: PGEOSDouble)
  : GEOSInt; cdecl; external External_library name 'GEOSCoordSeq_getOrdinate_r';

{
  * Get size and dimensions info from a Coordinate Sequence.
  * Return 0 on exception.
}
{ const } function GEOSCoordSeq_getSize(s: PGEOSCoordSequence; size: PGEOSUInt)
  : GEOSInt; cdecl; external External_library name 'GEOSCoordSeq_getSize';

{ const } function GEOSCoordSeq_getDimensions(s: PGEOSCoordSequence;
  dims: PGEOSUInt): GEOSInt; cdecl;
  external External_library name 'GEOSCoordSeq_getDimensions';

{ const } function GEOSCoordSeq_getSize_r(handle: GEOSContextHandle_t;
  s: PGEOSCoordSequence; size: PGEOSUInt): GEOSInt; cdecl;
  external External_library name 'GEOSCoordSeq_getSize_r';

{ const } function GEOSCoordSeq_getDimensions_r(handle: GEOSContextHandle_t;
  s: PGEOSCoordSequence; dims: PGEOSUInt): GEOSInt; cdecl;
  external External_library name 'GEOSCoordSeq_getDimensions_r';

{ ***********************************************************************
  *
  *  Linear referencing functions -- there are more, but these are
  *  probably sufficient for most purposes
  *
  ********************************************************************** }
{
  * GEOSGeometry ownership is retained by caller
}
{ Return distance of point 'p' projected on 'g' from origin
  * of 'g'. Geometry 'g' must be a lineal geometry }
{ const }  { const }
function GEOSProject(g: PGEOSGeometry; p: PGEOSGeometry): GEOSDouble; cdecl;
  external External_library name 'GEOSProject';

{ const }  { const }
function GEOSProject_r(handle: GEOSContextHandle_t; g: PGEOSGeometry;
  p: PGEOSGeometry): GEOSDouble; cdecl;
  external External_library name 'GEOSProject_r';

{ Return closest point to given distance within geometry
  * Geometry must be a LineString }
{ const } function GEOSInterpolate(g: PGEOSGeometry; d: GEOSDouble)
  : PGEOSGeometry; cdecl; external External_library name 'GEOSInterpolate';

{ const } function GEOSInterpolate_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry; d: GEOSDouble): PGEOSGeometry; cdecl;
  external External_library name 'GEOSInterpolate_r';

{ const }  { const }
function GEOSProjectNormalized(g: PGEOSGeometry; p: PGEOSGeometry): GEOSDouble;
  cdecl; external External_library name 'GEOSProjectNormalized';

{ const }  { const }
function GEOSProjectNormalized_r(handle: GEOSContextHandle_t; g: PGEOSGeometry;
  p: PGEOSGeometry): GEOSDouble; cdecl;
  external External_library name 'GEOSProjectNormalized_r';

{ const } function GEOSInterpolateNormalized(g: PGEOSGeometry; d: GEOSDouble)
  : PGEOSGeometry; cdecl;
  external External_library name 'GEOSInterpolateNormalized';

{ const } function GEOSInterpolateNormalized_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry; d: GEOSDouble): PGEOSGeometry; cdecl;
  external External_library name 'GEOSInterpolateNormalized_r';

{ ***********************************************************************
  *
  * Buffer related functions
  *
  ********************************************************************** }
{ @return NULL on exception }
{ const } function GEOSBuffer(g: PGEOSGeometry; width: GEOSDouble;
  quadsegs: GEOSInt): PGEOSGeometry; cdecl;
  external External_library name 'GEOSBuffer';

{ const } function GEOSBuffer_r(handle: GEOSContextHandle_t; g: PGEOSGeometry;
  width: GEOSDouble; quadsegs: GEOSInt): PGEOSGeometry; cdecl;
  external External_library name 'GEOSBuffer_r';


  { @return 0 on exception }

function GEOSBufferParams_create: PGEOSBufferParams; cdecl;
  external External_library name 'GEOSBufferParams_create';

function GEOSBufferParams_create_r(handle: GEOSContextHandle_t)
  : PGEOSBufferParams; cdecl;
  external External_library name 'GEOSBufferParams_create_r';

procedure GEOSBufferParams_destroy(parms: PGEOSBufferParams); cdecl;
  external External_library name 'GEOSBufferParams_destroy';

procedure GEOSBufferParams_destroy_r(handle: GEOSContextHandle_t;
  parms: PGEOSBufferParams); cdecl;
  external External_library name 'GEOSBufferParams_destroy_r';

{ @return 0 on exception }
function GEOSBufferParams_setEndCapStyle(p: PGEOSBufferParams; style: GEOSInt)
  : GEOSInt; cdecl;
  external External_library name 'GEOSBufferParams_setEndCapStyle';

function GEOSBufferParams_setEndCapStyle_r(handle: GEOSContextHandle_t;
  p: PGEOSBufferParams; style: GEOSInt): GEOSInt; cdecl;
  external External_library name 'GEOSBufferParams_setEndCapStyle_r';

{ @return 0 on exception }
function GEOSBufferParams_setJoinStyle(p: PGEOSBufferParams; joinStyle: GEOSInt)
  : GEOSInt; cdecl;
  external External_library name 'GEOSBufferParams_setJoinStyle';

function GEOSBufferParams_setJoinStyle_r(handle: GEOSContextHandle_t;
  p: PGEOSBufferParams; joinStyle: GEOSInt): GEOSInt; cdecl;
  external External_library name 'GEOSBufferParams_setJoinStyle_r';

{ @return 0 on exception }
function GEOSBufferParams_setMitreLimit(p: PGEOSBufferParams;
  mitreLimit: GEOSDouble): GEOSInt; cdecl;
  external External_library name 'GEOSBufferParams_setMitreLimit';

function GEOSBufferParams_setMitreLimit_r(handle: GEOSContextHandle_t;
  p: PGEOSBufferParams; mitreLimit: GEOSDouble): GEOSInt; cdecl;
  external External_library name 'GEOSBufferParams_setMitreLimit_r';

{ @return 0 on exception }
function GEOSBufferParams_setQuadrantSegments(p: PGEOSBufferParams;
  quadsegs: GEOSInt): GEOSInt; cdecl;
  external External_library name 'GEOSBufferParams_setQuadrantSegments';

function GEOSBufferParams_setQuadrantSegments_r(handle: GEOSContextHandle_t;
  p: PGEOSBufferParams; quadsegs: GEOSInt): GEOSInt; cdecl;
  external External_library name 'GEOSBufferParams_setQuadrantSegments_r';

{ @param singleSided: 1 for single sided, 0 otherwise }
{ @return 0 on exception }
function GEOSBufferParams_setSingleSided(p: PGEOSBufferParams;
  singleSided: GEOSInt): GEOSInt; cdecl;
  external External_library name 'GEOSBufferParams_setSingleSided';

function GEOSBufferParams_setSingleSided_r(handle: GEOSContextHandle_t;
  p: PGEOSBufferParams; singleSided: GEOSInt): GEOSInt; cdecl;
  external External_library name 'GEOSBufferParams_setSingleSided_r';

{ @return NULL on exception }
{ const }  { const }
function GEOSBufferWithParams(g: PGEOSGeometry; p: PGEOSBufferParams;
  width: GEOSDouble): PGEOSGeometry; cdecl;
  external External_library name 'GEOSBufferWithParams';

{ const }  { const }
function GEOSBufferWithParams_r(handle: GEOSContextHandle_t; g: PGEOSGeometry;
  p: PGEOSBufferParams; width: GEOSDouble): PGEOSGeometry; cdecl;
  external External_library name 'GEOSBufferWithParams_r';

{ These functions return NULL on exception. }
{ const } function GEOSBufferWithStyle(g: PGEOSGeometry; width: GEOSDouble;
  quadsegs: GEOSInt; endCapStyle: GEOSInt; joinStyle: GEOSInt;
  mitreLimit: GEOSDouble): PGEOSGeometry; cdecl;
  external External_library name 'GEOSBufferWithStyle';

{ const } function GEOSBufferWithStyle_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry; width: GEOSDouble; quadsegs: GEOSInt; endCapStyle: GEOSInt;
  joinStyle: GEOSInt; mitreLimit: GEOSDouble): PGEOSGeometry; cdecl;
  external External_library name 'GEOSBufferWithStyle_r';

{ These functions return NULL on exception. Only LINESTRINGs are accepted. }
{ @deprecated in 3.3.0: use GEOSOffsetCurve instead }
{ const } function GEOSSingleSidedBuffer(g: PGEOSGeometry; width: GEOSDouble;
  quadsegs: GEOSInt; joinStyle: GEOSInt; mitreLimit: GEOSDouble;
  leftSide: GEOSInt): PGEOSGeometry; cdecl;
  external External_library name 'GEOSSingleSidedBuffer';

{ const } function GEOSSingleSidedBuffer_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry; width: GEOSDouble; quadsegs: GEOSInt; joinStyle: GEOSInt;
  mitreLimit: GEOSDouble; leftSide: GEOSInt): PGEOSGeometry; cdecl;
  external External_library name 'GEOSSingleSidedBuffer_r';

{
  * Only LINESTRINGs are accepted.
  * @param width : offset distance.
  *                negative for right side offset.
  *                positive for left side offset.
  * @return NULL on exception
}
{ const } function GEOSOffsetCurve(g: PGEOSGeometry; width: GEOSDouble;
  quadsegs: GEOSInt; joinStyle: GEOSInt; mitreLimit: GEOSDouble): PGEOSGeometry;
  cdecl; external External_library name 'GEOSOffsetCurve';

{ const } function GEOSOffsetCurve_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry; width: GEOSDouble; quadsegs: GEOSInt; joinStyle: GEOSInt;
  mitreLimit: GEOSDouble): PGEOSGeometry; cdecl;
  external External_library name 'GEOSOffsetCurve_r';

{ ***********************************************************************
  *
  * Geometry Constructors.
  * GEOSCoordSequence* arguments will become ownership of the returned object.
  * All functions return NULL on exception.
  *
  ********************************************************************** }
function GEOSGeom_createPoint(s: PGEOSCoordSequence): PGEOSGeometry; cdecl;
  external External_library name 'GEOSGeom_createPoint';

function GEOSGeom_createEmptyPoint: PGEOSGeometry; cdecl;
  external External_library name 'GEOSGeom_createEmptyPoint';

function GEOSGeom_createLinearRing(s: PGEOSCoordSequence): PGEOSGeometry; cdecl;
  external External_library name 'GEOSGeom_createLinearRing';

function GEOSGeom_createLineString(s: PGEOSCoordSequence): PGEOSGeometry; cdecl;
  external External_library name 'GEOSGeom_createLineString';

function GEOSGeom_createEmptyLineString: PGEOSGeometry; cdecl;
  external External_library name 'GEOSGeom_createEmptyLineString';

function GEOSGeom_createPoint_r(handle: GEOSContextHandle_t;
  s: PGEOSCoordSequence): PGEOSGeometry; cdecl;
  external External_library name 'GEOSGeom_createPoint_r';

function GEOSGeom_createEmptyPoint_r(handle: GEOSContextHandle_t)
  : PGEOSGeometry; cdecl;
  external External_library name 'GEOSGeom_createEmptyPoint_r';

function GEOSGeom_createLinearRing_r(handle: GEOSContextHandle_t;
  s: PGEOSCoordSequence): PGEOSGeometry; cdecl;
  external External_library name 'GEOSGeom_createLinearRing_r';

function GEOSGeom_createLineString_r(handle: GEOSContextHandle_t;
  s: PGEOSCoordSequence): PGEOSGeometry; cdecl;
  external External_library name 'GEOSGeom_createLineString_r';

function GEOSGeom_createEmptyLineString_r(handle: GEOSContextHandle_t)
  : PGEOSGeometry; cdecl;
  external External_library name 'GEOSGeom_createEmptyLineString_r';

{
  * Second argument is an array of GEOSGeometry* objects.
  * The caller remains owner of the array, but pointed-to
  * objects become ownership of the returned GEOSGeometry.
}
function GEOSGeom_createEmptyPolygon: PGEOSGeometry; cdecl;
  external External_library name 'GEOSGeom_createEmptyPolygon';

function GEOSGeom_createPolygon(shell: PGEOSGeometry; holes: PPGEOSGeometry;
  nholes: GEOSUInt): PGEOSGeometry; cdecl;
  external External_library name 'GEOSGeom_createPolygon';

function GEOSGeom_createCollection(_type: GEOSInt; geoms: PPGEOSGeometry;
  ngeoms: GEOSUInt): PGEOSGeometry; cdecl;
  external External_library name 'GEOSGeom_createCollection';

function GEOSGeom_createEmptyCollection(_type: GEOSInt): PGEOSGeometry; cdecl;
  external External_library name 'GEOSGeom_createEmptyCollection';

function GEOSGeom_createEmptyPolygon_r(handle: GEOSContextHandle_t)
  : PGEOSGeometry; cdecl;
  external External_library name 'GEOSGeom_createEmptyPolygon_r';

function GEOSGeom_createPolygon_r(handle: GEOSContextHandle_t;
  shell: PGEOSGeometry; holes: PPGEOSGeometry; nholes: GEOSUInt): PGEOSGeometry;
  cdecl; external External_library name 'GEOSGeom_createPolygon_r';

function GEOSGeom_createCollection_r(handle: GEOSContextHandle_t;
  _type: GEOSInt; geoms: PPGEOSGeometry; ngeoms: GEOSUInt): PGEOSGeometry;
  cdecl; external External_library name 'GEOSGeom_createCollection_r';

function GEOSGeom_createEmptyCollection_r(handle: GEOSContextHandle_t;
  _type: GEOSInt): PGEOSGeometry; cdecl;
  external External_library name 'GEOSGeom_createEmptyCollection_r';

{ const } function GEOSGeom_clone(g: PGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSGeom_clone';

{ const } function GEOSGeom_clone_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSGeom_clone_r';

{ ***********************************************************************
  *
  * Memory management
  *
  ********************************************************************** }
procedure GEOSGeom_destroy(g: PGEOSGeometry); cdecl;
  external External_library name 'GEOSGeom_destroy';

procedure GEOSGeom_destroy_r(handle: GEOSContextHandle_t; g: PGEOSGeometry);
  cdecl; external External_library name 'GEOSGeom_destroy_r';

{ ***********************************************************************
  *
  * Topology operations - return NULL on exception.
  *
  ********************************************************************** }
{ const } function GEOSEnvelope(g: PGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSEnvelope';

{ const }  { const }
function GEOSIntersection(g1: PGEOSGeometry; g2: PGEOSGeometry): PGEOSGeometry;
  cdecl; external External_library name 'GEOSIntersection';

{ const } function GEOSConvexHull(g: PGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSConvexHull';

{ const }  { const }
function GEOSDifference(g1: PGEOSGeometry; g2: PGEOSGeometry): PGEOSGeometry;
  cdecl; external External_library name 'GEOSDifference';

{ const }  { const }
function GEOSSymDifference(g1: PGEOSGeometry; g2: PGEOSGeometry): PGEOSGeometry;
  cdecl; external External_library name 'GEOSSymDifference';

{ const } function GEOSBoundary(g: PGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSBoundary';

{ const }  { const }
function GEOSUnion(g1: PGEOSGeometry; g2: PGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSUnion';

{ const } function GEOSUnaryUnion(g: PGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSUnaryUnion';

{ @deprecated in 3.3.0: use GEOSUnaryUnion instead }
{ const } function GEOSUnionCascaded(g: PGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSUnionCascaded';

{ const } function GEOSPointOnSurface(g: PGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSPointOnSurface';

{ const } function GEOSGetCentroid(g: PGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSGetCentroid';

{ const } function GEOSNode(g: PGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSNode';

{ const } function GEOSEnvelope_r(handle: GEOSContextHandle_t; g: PGEOSGeometry)
  : PGEOSGeometry; cdecl; external External_library name 'GEOSEnvelope_r';

{ const }  { const }
function GEOSIntersection_r(handle: GEOSContextHandle_t; g1: PGEOSGeometry;
  g2: PGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSIntersection_r';

{ const } function GEOSConvexHull_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSConvexHull_r';

{ const }  { const }
function GEOSDifference_r(handle: GEOSContextHandle_t; g1: PGEOSGeometry;
  g2: PGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSDifference_r';

{ const }  { const }
function GEOSSymDifference_r(handle: GEOSContextHandle_t; g1: PGEOSGeometry;
  g2: PGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSSymDifference_r';

{ const } function GEOSBoundary_r(handle: GEOSContextHandle_t; g: PGEOSGeometry)
  : PGEOSGeometry; cdecl; external External_library name 'GEOSBoundary_r';

{ const }  { const }
function GEOSUnion_r(handle: GEOSContextHandle_t; g1: PGEOSGeometry;
  g2: PGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSUnion_r';

{ const } function GEOSUnaryUnion_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSUnaryUnion_r';

{ const } function GEOSUnionCascaded_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSUnionCascaded_r';

{ const } function GEOSPointOnSurface_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSPointOnSurface_r';

{ const } function GEOSGetCentroid_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSGetCentroid_r';

{ const } function GEOSNode_r(handle: GEOSContextHandle_t; g: PGEOSGeometry)
  : PGEOSGeometry; cdecl; external External_library name 'GEOSNode_r';

{
  * all arguments remain ownership of the caller
  * (both Geometries and pointers)
}
{ const }  { const }
function GEOSPolygonize(geoms: array of PGEOSGeometry; ngeoms: GEOSUInt)
  : PGEOSGeometry; cdecl; external External_library name 'GEOSPolygonize';

{ const }  { const }
function GEOSPolygonizer_getCutEdges(geoms: array of PGEOSGeometry;
  ngeoms: GEOSUInt): PGEOSGeometry; cdecl;
  external External_library name 'GEOSPolygonizer_getCutEdges';

{
  * Polygonizes a set of Geometries which contain linework that
  * represents the edges of a planar graph.
  *
  * Any dimension of Geometry is handled - the constituent linework
  * is extracted to form the edges.
  *
  * The edges must be correctly noded; that is, they must only meet
  * at their endpoints.
  * The Polygonizer will still run on incorrectly noded input
  * but will not form polygons from incorrectly noded edges.
  *
  * The Polygonizer reports the follow kinds of errors:
  *
  * - Dangles - edges which have one or both ends which are
  *   not incident on another edge endpoint
  * - Cut Edges - edges which are connected at both ends but
  *   which do not form part of polygon
  * - Invalid Ring Lines - edges which form rings which are invalid
  *   (e.g. the component lines contain a self-intersection)
  *
  * Errors are reported to output parameters "cuts", "dangles" and
  * "invalid" (if not-null). Formed polygons are returned as a
  * collection. NULL is returned on exception. All returned
  * geometries must be destroyed by caller.
  *
}
{ const } function GEOSPolygonize_full(input: PGEOSGeometry;
  cuts: PPGEOSGeometry; dangles: PPGEOSGeometry; invalid: PPGEOSGeometry)
  : PGEOSGeometry; cdecl; external External_library name 'GEOSPolygonize_full';

{ const } function GEOSLineMerge(g: PGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSLineMerge';

{ const } function GEOSSimplify(g: PGEOSGeometry; tolerance: GEOSDouble)
  : PGEOSGeometry; cdecl; external External_library name 'GEOSSimplify';

{ const } function GEOSTopologyPreserveSimplify(g: PGEOSGeometry;
  tolerance: GEOSDouble): PGEOSGeometry; cdecl;
  external External_library name 'GEOSTopologyPreserveSimplify';

{ const }  { const }
function GEOSPolygonize_r(handle: GEOSContextHandle_t;
  geoms: array of PGEOSGeometry; ngeoms: GEOSUInt): PGEOSGeometry; cdecl;
  external External_library name 'GEOSPolygonize_r';

{ const }  { const }
function GEOSPolygonizer_getCutEdges_r(handle: GEOSContextHandle_t;
  geoms: array of PGEOSGeometry; ngeoms: GEOSUInt): PGEOSGeometry; cdecl;
  external External_library name 'GEOSPolygonizer_getCutEdges_r';

{ const } function GEOSPolygonize_full_r(handle: GEOSContextHandle_t;
  input: PGEOSGeometry; cuts: PPGEOSGeometry; dangles: PPGEOSGeometry;
  invalidRings: PPGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSPolygonize_full_r';

{ const } function GEOSLineMerge_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSLineMerge_r';

{ const } function GEOSSimplify_r(handle: GEOSContextHandle_t; g: PGEOSGeometry;
  tolerance: GEOSDouble): PGEOSGeometry; cdecl;
  external External_library name 'GEOSSimplify_r';

{ const } function GEOSTopologyPreserveSimplify_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry; tolerance: GEOSDouble): PGEOSGeometry; cdecl;
  external External_library name 'GEOSTopologyPreserveSimplify_r';

{
  * Return all distinct vertices of input geometry as a MULTIPOINT.
  * Note that only 2 dimensions of the vertices are considered when
  * testing for equality.
}
{ const } function GEOSGeom_extractUniquePoints(g: PGEOSGeometry)
  : PGEOSGeometry; cdecl;
  external External_library name 'GEOSGeom_extractUniquePoints';

{ const } function GEOSGeom_extractUniquePoints_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSGeom_extractUniquePoints_r';

{
  * Find paths shared between the two given lineal geometries.
  *
  * Returns a GEOMETRYCOLLECTION having two elements:
  * - first element is a MULTILINESTRING containing shared paths
  *   having the _same_ direction on both inputs
  * - second element is a MULTILINESTRING containing shared paths
  *   having the _opposite_ direction on the two inputs
  *
  * Returns NULL on exception
}
{ const }  { const }
function GEOSSharedPaths(g1: PGEOSGeometry; g2: PGEOSGeometry): PGEOSGeometry;
  cdecl; external External_library name 'GEOSSharedPaths';

{ const }  { const }
function GEOSSharedPaths_r(handle: GEOSContextHandle_t; g1: PGEOSGeometry;
  g2: PGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSSharedPaths_r';

{
  * Snap first geometry on to second with given tolerance
  * Returns a newly allocated geometry, or NULL on exception
}
{ const }  { const }
function GEOSSnap(g1: PGEOSGeometry; g2: PGEOSGeometry; tolerance: GEOSDouble)
  : PGEOSGeometry; cdecl; external External_library name 'GEOSSnap';

{ const }  { const }
function GEOSSnap_r(handle: GEOSContextHandle_t; g1: PGEOSGeometry;
  g2: PGEOSGeometry; tolerance: GEOSDouble): PGEOSGeometry; cdecl;
  external External_library name 'GEOSSnap_r';

{
  * Return a Delaunay triangulation of the vertex of the given geometry
  *
  * @param g the input geometry whose vertex will be used as "sites"
  * @param tolerance optional snapping tolerance to use for improved robustness
  * @param onlyEdges if non-zero will return a MULTILINESTRING, otherwise it will
  *                  return a GEOMETRYCOLLECTION containing triangular POLYGONs.
  *
  * @return  a newly allocated geometry, or NULL on exception
}
{ const } function GEOSDelaunayTriangulation(g: PGEOSGeometry;
  tolerance: GEOSDouble; onlyEdges: GEOSInt): PGEOSGeometry; cdecl;
  external External_library name 'GEOSDelaunayTriangulation';

{ const } function GEOSDelaunayTriangulation_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry; tolerance: GEOSDouble; onlyEdges: GEOSInt): PGEOSGeometry;
  cdecl; external External_library name 'GEOSDelaunayTriangulation_r';

{ ***********************************************************************
  *
  *  Binary predicates - return 2 on exception, 1 on true, 0 on false
  *
  ********************************************************************** }
{ const }  { const }
function GEOSDisjoint(g1: PGEOSGeometry; g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSDisjoint';

{ const }  { const }
function GEOSTouches(g1: PGEOSGeometry; g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSTouches';

{ const }  { const }
function GEOSIntersects(g1: PGEOSGeometry; g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSIntersects';

{ const }  { const }
function GEOSCrosses(g1: PGEOSGeometry; g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSCrosses';

{ const }  { const }
function GEOSWithin(g1: PGEOSGeometry; g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSWithin';

{ const }  { const }
function GEOSContains(g1: PGEOSGeometry; g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSContains';

{ const }  { const }
function GEOSOverlaps(g1: PGEOSGeometry; g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSOverlaps';

{ const }  { const }
function GEOSEquals(g1: PGEOSGeometry; g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSEquals';

{ const }  { const }
function GEOSEqualsExact(g1: PGEOSGeometry; g2: PGEOSGeometry;
  tolerance: GEOSDouble): GEOSChar; cdecl;
  external External_library name 'GEOSEqualsExact';

{ const }  { const }
function GEOSCovers(g1: PGEOSGeometry; g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSCovers';

{ const }  { const }
function GEOSCoveredBy(g1: PGEOSGeometry; g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSCoveredBy';

{ const }  { const }
function GEOSDisjoint_r(handle: GEOSContextHandle_t; g1: PGEOSGeometry;
  g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSDisjoint_r';

{ const }  { const }
function GEOSTouches_r(handle: GEOSContextHandle_t; g1: PGEOSGeometry;
  g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSTouches_r';

{ const }  { const }
function GEOSIntersects_r(handle: GEOSContextHandle_t; g1: PGEOSGeometry;
  g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSIntersects_r';

{ const }  { const }
function GEOSCrosses_r(handle: GEOSContextHandle_t; g1: PGEOSGeometry;
  g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSCrosses_r';

{ const }  { const }
function GEOSWithin_r(handle: GEOSContextHandle_t; g1: PGEOSGeometry;
  g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSWithin_r';

{ const }  { const }
function GEOSContains_r(handle: GEOSContextHandle_t; g1: PGEOSGeometry;
  g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSContains_r';

{ const }  { const }
function GEOSOverlaps_r(handle: GEOSContextHandle_t; g1: PGEOSGeometry;
  g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSOverlaps_r';

{ const }  { const }
function GEOSEquals_r(handle: GEOSContextHandle_t; g1: PGEOSGeometry;
  g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSEquals_r';

{ const }  { const }
function GEOSEqualsExact_r(handle: GEOSContextHandle_t; g1: PGEOSGeometry;
  g2: PGEOSGeometry; tolerance: GEOSDouble): GEOSChar; cdecl;
  external External_library name 'GEOSEqualsExact_r';

{ const }  { const }
function GEOSCovers_r(handle: GEOSContextHandle_t; g1: PGEOSGeometry;
  g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSCovers_r';

{ const }  { const }
function GEOSCoveredBy_r(handle: GEOSContextHandle_t; g1: PGEOSGeometry;
  g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSCoveredBy_r';

{ ***********************************************************************
  *
  *  Prepared Geometry Binary predicates - return 2 on exception, 1 on true, 0 on false
  *
  ********************************************************************** }
{
  * GEOSGeometry ownership is retained by caller
}
{ const }  { const }
function GEOSPrepare(g: PGEOSGeometry): PGEOSPreparedGeometry; cdecl;
  external External_library name 'GEOSPrepare';

{ const } procedure GEOSPreparedGeom_destroy(g: PGEOSPreparedGeometry); cdecl;
  external External_library name 'GEOSPreparedGeom_destroy';

{ const }  { const }
function GEOSPreparedContains(pg1: PGEOSPreparedGeometry; g2: PGEOSGeometry)
  : GEOSChar; cdecl; external External_library name 'GEOSPreparedContains';

{ const }  { const }
function GEOSPreparedContainsProperly(pg1: PGEOSPreparedGeometry;
  g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSPreparedContainsProperly';

{ const }  { const }
function GEOSPreparedCoveredBy(pg1: PGEOSPreparedGeometry; g2: PGEOSGeometry)
  : GEOSChar; cdecl; external External_library name 'GEOSPreparedCoveredBy';

{ const }  { const }
function GEOSPreparedCovers(pg1: PGEOSPreparedGeometry; g2: PGEOSGeometry)
  : GEOSChar; cdecl; external External_library name 'GEOSPreparedCovers';

{ const }  { const }
function GEOSPreparedCrosses(pg1: PGEOSPreparedGeometry; g2: PGEOSGeometry)
  : GEOSChar; cdecl; external External_library name 'GEOSPreparedCrosses';

{ const }  { const }
function GEOSPreparedDisjoint(pg1: PGEOSPreparedGeometry; g2: PGEOSGeometry)
  : GEOSChar; cdecl; external External_library name 'GEOSPreparedDisjoint';

{ const }  { const }
function GEOSPreparedIntersects(pg1: PGEOSPreparedGeometry; g2: PGEOSGeometry)
  : GEOSChar; cdecl; external External_library name 'GEOSPreparedIntersects';

{ const }  { const }
function GEOSPreparedOverlaps(pg1: PGEOSPreparedGeometry; g2: PGEOSGeometry)
  : GEOSChar; cdecl; external External_library name 'GEOSPreparedOverlaps';

{ const }  { const }
function GEOSPreparedTouches(pg1: PGEOSPreparedGeometry; g2: PGEOSGeometry)
  : GEOSChar; cdecl; external External_library name 'GEOSPreparedTouches';

{ const }  { const }
function GEOSPreparedWithin(pg1: PGEOSPreparedGeometry; g2: PGEOSGeometry)
  : GEOSChar; cdecl; external External_library name 'GEOSPreparedWithin';

{
  * GEOSGeometry ownership is retained by caller
}
{ const }  { const }
function GEOSPrepare_r(handle: GEOSContextHandle_t; g: PGEOSGeometry)
  : PGEOSPreparedGeometry; cdecl;
  external External_library name 'GEOSPrepare_r';

{ const } procedure GEOSPreparedGeom_destroy_r(handle: GEOSContextHandle_t;
  g: PGEOSPreparedGeometry); cdecl;
  external External_library name 'GEOSPreparedGeom_destroy_r';

{ const }  { const }
function GEOSPreparedContains_r(handle: GEOSContextHandle_t;
  pg1: PGEOSPreparedGeometry; g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSPreparedContains_r';

{ const }  { const }
function GEOSPreparedContainsProperly_r(handle: GEOSContextHandle_t;
  pg1: PGEOSPreparedGeometry; g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSPreparedContainsProperly_r';

{ const }  { const }
function GEOSPreparedCoveredBy_r(handle: GEOSContextHandle_t;
  pg1: PGEOSPreparedGeometry; g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSPreparedCoveredBy_r';

{ const }  { const }
function GEOSPreparedCovers_r(handle: GEOSContextHandle_t;
  pg1: PGEOSPreparedGeometry; g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSPreparedCovers_r';

{ const }  { const }
function GEOSPreparedCrosses_r(handle: GEOSContextHandle_t;
  pg1: PGEOSPreparedGeometry; g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSPreparedCrosses_r';

{ const }  { const }
function GEOSPreparedDisjoint_r(handle: GEOSContextHandle_t;
  pg1: PGEOSPreparedGeometry; g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSPreparedDisjoint_r';

{ const }  { const }
function GEOSPreparedIntersects_r(handle: GEOSContextHandle_t;
  pg1: PGEOSPreparedGeometry; g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSPreparedIntersects_r';

{ const }  { const }
function GEOSPreparedOverlaps_r(handle: GEOSContextHandle_t;
  pg1: PGEOSPreparedGeometry; g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSPreparedOverlaps_r';

{ const }  { const }
function GEOSPreparedTouches_r(handle: GEOSContextHandle_t;
  pg1: PGEOSPreparedGeometry; g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSPreparedTouches_r';

{ const }  { const }
function GEOSPreparedWithin_r(handle: GEOSContextHandle_t;
  pg1: PGEOSPreparedGeometry; g2: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSPreparedWithin_r';

{ ***********************************************************************
  *
  *  STRtree functions
  *
  ********************************************************************** }
{
  * GEOSGeometry ownership is retained by caller
}
function GEOSSTRtree_create(nodeCapacity: GEOSsize_t): PGEOSSTRtree; cdecl;
  external External_library name 'GEOSSTRtree_create';

{ const } procedure GEOSSTRtree_insert(tree: PGEOSSTRtree; g: PGEOSGeometry;
  item: pointer); cdecl; external External_library name 'GEOSSTRtree_insert';

{ const } procedure GEOSSTRtree_query(tree: PGEOSSTRtree; g: PGEOSGeometry;
  callback: GEOSQueryCallback; userdata: pointer); cdecl;
  external External_library name 'GEOSSTRtree_query';

procedure GEOSSTRtree_iterate(tree: PGEOSSTRtree; callback: GEOSQueryCallback;
  userdata: pointer); cdecl;
  external External_library name 'GEOSSTRtree_iterate';

{ const } function GEOSSTRtree_remove(tree: PGEOSSTRtree; g: PGEOSGeometry;
  item: pointer): GEOSChar; cdecl;
  external External_library name 'GEOSSTRtree_remove';

procedure GEOSSTRtree_destroy(tree: PGEOSSTRtree); cdecl;
  external External_library name 'GEOSSTRtree_destroy';

function GEOSSTRtree_create_r(handle: GEOSContextHandle_t;
  nodeCapacity: GEOSsize_t): PGEOSSTRtree; cdecl;
  external External_library name 'GEOSSTRtree_create_r';

{ const } procedure GEOSSTRtree_insert_r(handle: GEOSContextHandle_t;
  tree: PGEOSSTRtree; g: PGEOSGeometry; item: pointer); cdecl;
  external External_library name 'GEOSSTRtree_insert_r';

{ const } procedure GEOSSTRtree_query_r(handle: GEOSContextHandle_t;
  tree: PGEOSSTRtree; g: PGEOSGeometry; callback: GEOSQueryCallback;
  userdata: pointer); cdecl;
  external External_library name 'GEOSSTRtree_query_r';

procedure GEOSSTRtree_iterate_r(handle: GEOSContextHandle_t; tree: PGEOSSTRtree;
  callback: GEOSQueryCallback; userdata: pointer); cdecl;
  external External_library name 'GEOSSTRtree_iterate_r';

{ const } function GEOSSTRtree_remove_r(handle: GEOSContextHandle_t;
  tree: PGEOSSTRtree; g: PGEOSGeometry; item: pointer): GEOSChar; cdecl;
  external External_library name 'GEOSSTRtree_remove_r';

procedure GEOSSTRtree_destroy_r(handle: GEOSContextHandle_t;
  tree: PGEOSSTRtree); cdecl;
  external External_library name 'GEOSSTRtree_destroy_r';

{ ***********************************************************************
  *
  *  Unary predicate - return 2 on exception, 1 on true, 0 on false
  *
  ********************************************************************** }
{ const } function GEOSisEmpty(g: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSisEmpty';

{ const } function GEOSisSimple(g: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSisSimple';

{ const } function GEOSisRing(g: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSisRing';

{ const } function GEOSHasZ(g: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSHasZ';

{ const } function GEOSisClosed(g: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSisClosed';

{ const } function GEOSisEmpty_r(handle: GEOSContextHandle_t; g: PGEOSGeometry)
  : GEOSChar; cdecl; external External_library name 'GEOSisEmpty_r';

{ const } function GEOSisSimple_r(handle: GEOSContextHandle_t; g: PGEOSGeometry)
  : GEOSChar; cdecl; external External_library name 'GEOSisSimple_r';

{ const } function GEOSisRing_r(handle: GEOSContextHandle_t; g: PGEOSGeometry)
  : GEOSChar; cdecl; external External_library name 'GEOSisRing_r';

{ const } function GEOSHasZ_r(handle: GEOSContextHandle_t; g: PGEOSGeometry)
  : GEOSChar; cdecl; external External_library name 'GEOSHasZ_r';

{ const } function GEOSisClosed_r(handle: GEOSContextHandle_t; g: PGEOSGeometry)
  : GEOSChar; cdecl; external External_library name 'GEOSisClosed_r';

{ ***********************************************************************
  *
  *  Dimensionally Extended 9 Intersection Model related
  *
  ********************************************************************** }
{ These are for use with GEOSRelateBoundaryNodeRule (flags param) }
{ MOD2 and OGC are the same rule, and is the default
  * used by GEOSRelatePattern
}

type
  GEOSRelateBoundaryNodeRules = (GEOSRELATE_BNR_MOD2 = 1, GEOSRELATE_BNR_OGC =
    1, GEOSRELATE_BNR_ENDPOINT = 2, GEOSRELATE_BNR_MULTIVALENT_ENDPOINT = 3,
    GEOSRELATE_BNR_MONOVALENT_ENDPOINT = 4);

  { return 2 on exception, 1 on true, 0 on false }
  { const }  { const }  { const }
function GEOSRelatePattern(g1: PGEOSGeometry; g2: PGEOSGeometry; pat: PGEOSChar)
  : GEOSChar; cdecl; external External_library name 'GEOSRelatePattern';

{ const }  { const }  { const }
function GEOSRelatePattern_r(handle: GEOSContextHandle_t; g1: PGEOSGeometry;
  g2: PGEOSGeometry; pat: PGEOSChar): GEOSChar; cdecl;
  external External_library name 'GEOSRelatePattern_r';

{ return NULL on exception, a string to GEOSFree otherwise }
{ const }  { const }
function GEOSRelate(g1: PGEOSGeometry; g2: PGEOSGeometry): PGEOSChar; cdecl;
  external External_library name 'GEOSRelate';

{ const }  { const }
function GEOSRelate_r(handle: GEOSContextHandle_t; g1: PGEOSGeometry;
  g2: PGEOSGeometry): PGEOSChar; cdecl;
  external External_library name 'GEOSRelate_r';

{ return 2 on exception, 1 on true, 0 on false }
{ const }  { const }
function GEOSRelatePatternMatch(mat: PGEOSChar; pat: PGEOSChar): GEOSChar;
  cdecl; external External_library name 'GEOSRelatePatternMatch';

{ const }  { const }
function GEOSRelatePatternMatch_r(handle: GEOSContextHandle_t; mat: PGEOSChar;
  pat: PGEOSChar): GEOSChar; cdecl;
  external External_library name 'GEOSRelatePatternMatch_r';

{ return NULL on exception, a string to GEOSFree otherwise }
{ const }  { const }
function GEOSRelateBoundaryNodeRule(g1: PGEOSGeometry; g2: PGEOSGeometry;
  bnr: GEOSInt): PGEOSChar; cdecl;
  external External_library name 'GEOSRelateBoundaryNodeRule';

{ const }  { const }
function GEOSRelateBoundaryNodeRule_r(handle: GEOSContextHandle_t;
  g1: PGEOSGeometry; g2: PGEOSGeometry; bnr: GEOSInt): PGEOSChar; cdecl;
  external External_library name 'GEOSRelateBoundaryNodeRule_r';

{ ***********************************************************************
  *
  *  Validity checking
  *
  ********************************************************************** }
{ These are for use with GEOSisValidDetail (flags param) }

type
  GEOSValidFlags = (GEOSVALID_ALLOW_SELFTOUCHING_RING_FORMING_HOLE = 1);

  { return 2 on exception, 1 on true, 0 on false }
  { const }
function GEOSisValid(g: PGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSisValid';

{ const } function GEOSisValid_r(handle: GEOSContextHandle_t; g: PGEOSGeometry)
  : GEOSChar; cdecl; external External_library name 'GEOSisValid_r';

{ return NULL on exception, a string to GEOSFree otherwise }
{ const } function GEOSisValidReason(g: PGEOSGeometry): PGEOSChar; cdecl;
  external External_library name 'GEOSisValidReason';

{ const } function GEOSisValidReason_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry): PGEOSChar; cdecl;
  external External_library name 'GEOSisValidReason_r';

{
  * Caller has the responsibility to destroy 'reason' (GEOSFree)
  * and 'location' (GEOSGeom_destroy) params
  * return 2 on exception, 1 when valid, 0 when invalid
}
{ const } function GEOSisValidDetail(g: PGEOSGeometry; flags: GEOSInt;
  reason: PPGEOSChar; location: PPGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSisValidDetail';

{ const } function GEOSisValidDetail_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry; flags: GEOSInt; reason: PPGEOSChar;
  location: PPGEOSGeometry): GEOSChar; cdecl;
  external External_library name 'GEOSisValidDetail_r';

{ ***********************************************************************
  *
  *  Geometry info
  *
  ********************************************************************** }
{ Return NULL on exception, result must be freed by caller. }
{ const } function GEOSGeomType(g: PGEOSGeometry): PGEOSChar; cdecl;
  external External_library name 'GEOSGeomType';

{ const } function GEOSGeomType_r(handle: GEOSContextHandle_t; g: PGEOSGeometry)
  : PGEOSChar; cdecl; external External_library name 'GEOSGeomType_r';

{ Return -1 on exception }
{ const } function GEOSGeomTypeId(g: PGEOSGeometry): GEOSInt; cdecl;
  external External_library name 'GEOSGeomTypeId';

{ const } function GEOSGeomTypeId_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry): GEOSInt; cdecl;
  external External_library name 'GEOSGeomTypeId_r';

{ Return 0 on exception }
{ const } function GEOSGetSRID(g: PGEOSGeometry): GEOSInt; cdecl;
  external External_library name 'GEOSGetSRID';

{ const } function GEOSGetSRID_r(handle: GEOSContextHandle_t; g: PGEOSGeometry)
  : GEOSInt; cdecl; external External_library name 'GEOSGetSRID_r';

procedure GEOSSetSRID(g: PGEOSGeometry; SRID: GEOSInt); cdecl;
  external External_library name 'GEOSSetSRID';

procedure GEOSSetSRID_r(handle: GEOSContextHandle_t; g: PGEOSGeometry;
  SRID: GEOSInt); cdecl; external External_library name 'GEOSSetSRID_r';

{ May be called on all geometries in GEOS 3.x, returns -1 on error and 1
  * for non-multi geometries. Older GEOS versions only accept
  * GeometryCollections or Multi* geometries here, and are likely to crash
  * when fed simple geometries, so beware if you need compatibility with
  * old GEOS versions.
}
{ const } function GEOSGetNumGeometries(g: PGEOSGeometry): GEOSInt; cdecl;
  external External_library name 'GEOSGetNumGeometries';

{ const } function GEOSGetNumGeometries_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry): GEOSInt; cdecl;
  external External_library name 'GEOSGetNumGeometries_r';

{
  * Return NULL on exception.
  * Returned object is a pointer to internal storage:
  * it must NOT be destroyed directly.
  * Up to GEOS 3.2.0 the input geometry must be a Collection, in
  * later version it doesn't matter (getGeometryN(0) for a single will
  * return the input).
}
{ const }  { const }
function GEOSGetGeometryN(g: PGEOSGeometry; n: GEOSInt): PGEOSGeometry; cdecl;
  external External_library name 'GEOSGetGeometryN';

{ const }  { const }
function GEOSGetGeometryN_r(handle: GEOSContextHandle_t; g: PGEOSGeometry;
  n: GEOSInt): PGEOSGeometry; cdecl;
  external External_library name 'GEOSGetGeometryN_r';

{ Return -1 on exception }
function GEOSNormalize(g: PGEOSGeometry): GEOSInt; cdecl;
  external External_library name 'GEOSNormalize';

function GEOSNormalize_r(handle: GEOSContextHandle_t; g: PGEOSGeometry)
  : GEOSInt; cdecl; external External_library name 'GEOSNormalize_r';

{ Return -1 on exception }
{ const } function GEOSGetNumInteriorRings(g: PGEOSGeometry): GEOSInt; cdecl;
  external External_library name 'GEOSGetNumInteriorRings';

{ const } function GEOSGetNumInteriorRings_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry): GEOSInt; cdecl;
  external External_library name 'GEOSGetNumInteriorRings_r';

{ Return -1 on exception, Geometry must be a LineString. }
{ const } function GEOSGeomGetNumPoints(g: PGEOSGeometry): GEOSInt; cdecl;
  external External_library name 'GEOSGeomGetNumPoints';

{ const } function GEOSGeomGetNumPoints_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry): GEOSInt; cdecl;
  external External_library name 'GEOSGeomGetNumPoints_r';

{ Return -1 on exception, Geometry must be a Point. }
{ const } function GEOSGeomGetX(g: PGEOSGeometry; x: PGEOSDouble): GEOSInt;
  cdecl; external External_library name 'GEOSGeomGetX';

{ const } function GEOSGeomGetY(g: PGEOSGeometry; y: PGEOSDouble): GEOSInt;
  cdecl; external External_library name 'GEOSGeomGetY';

{ const } function GEOSGeomGetX_r(handle: GEOSContextHandle_t; g: PGEOSGeometry;
  x: PGEOSDouble): GEOSInt; cdecl;
  external External_library name 'GEOSGeomGetX_r';

{ const } function GEOSGeomGetY_r(handle: GEOSContextHandle_t; g: PGEOSGeometry;
  y: PGEOSDouble): GEOSInt; cdecl;
  external External_library name 'GEOSGeomGetY_r';

{
  * Return NULL on exception, Geometry must be a Polygon.
  * Returned object is a pointer to internal storage:
  * it must NOT be destroyed directly.
}
{ const }  { const }
function GEOSGetInteriorRingN(g: PGEOSGeometry; n: GEOSInt): PGEOSGeometry;
  cdecl; external External_library name 'GEOSGetInteriorRingN';

{ const }  { const }
function GEOSGetInteriorRingN_r(handle: GEOSContextHandle_t; g: PGEOSGeometry;
  n: GEOSInt): PGEOSGeometry; cdecl;
  external External_library name 'GEOSGetInteriorRingN_r';

{
  * Return NULL on exception, Geometry must be a Polygon.
  * Returned object is a pointer to internal storage:
  * it must NOT be destroyed directly.
}
{ const }  { const }
function GEOSGetExteriorRing(g: PGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSGetExteriorRing';

{ const }  { const }
function GEOSGetExteriorRing_r(handle: GEOSContextHandle_t; g: PGEOSGeometry)
  : PGEOSGeometry; cdecl;
  external External_library name 'GEOSGetExteriorRing_r';

{ Return -1 on exception }
{ const } function GEOSGetNumCoordinates(g: PGEOSGeometry): GEOSInt; cdecl;
  external External_library name 'GEOSGetNumCoordinates';

{ const } function GEOSGetNumCoordinates_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry): GEOSInt; cdecl;
  external External_library name 'GEOSGetNumCoordinates_r';

{
  * Return NULL on exception.
  * Geometry must be a LineString, LinearRing or Point.
}
{ const }  { const }
function GEOSGeom_getCoordSeq(g: PGEOSGeometry): PGEOSCoordSequence; cdecl;
  external External_library name 'GEOSGeom_getCoordSeq';

{ const }  { const }
function GEOSGeom_getCoordSeq_r(handle: GEOSContextHandle_t; g: PGEOSGeometry)
  : PGEOSCoordSequence; cdecl;
  external External_library name 'GEOSGeom_getCoordSeq_r';

{
  * Return 0 on exception (or empty geometry)
}
{ const } function GEOSGeom_getDimensions(g: PGEOSGeometry): GEOSInt; cdecl;
  external External_library name 'GEOSGeom_getDimensions';

{ const } function GEOSGeom_getDimensions_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry): GEOSInt; cdecl;
  external External_library name 'GEOSGeom_getDimensions_r';

{
  * Return 2 or 3.
}
{ const } function GEOSGeom_getCoordinateDimension(g: PGEOSGeometry): GEOSInt;
  cdecl; external External_library name 'GEOSGeom_getCoordinateDimension';

{ const } function GEOSGeom_getCoordinateDimension_r
  (handle: GEOSContextHandle_t; g: PGEOSGeometry): GEOSInt; cdecl;
  external External_library name 'GEOSGeom_getCoordinateDimension_r';

{
  * Return NULL on exception.
  * Must be LineString and must be freed by called.
}
{ const } function GEOSGeomGetPointN(g: PGEOSGeometry; n: GEOSInt)
  : PGEOSGeometry; cdecl; external External_library name 'GEOSGeomGetPointN';

{ const } function GEOSGeomGetStartPoint(g: PGEOSGeometry): PGEOSGeometry;
  cdecl; external External_library name 'GEOSGeomGetStartPoint';

{ const } function GEOSGeomGetEndPoint(g: PGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSGeomGetEndPoint';

{ const } function GEOSGeomGetPointN_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry; n: GEOSInt): PGEOSGeometry; cdecl;
  external External_library name 'GEOSGeomGetPointN_r';

{ const } function GEOSGeomGetStartPoint_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSGeomGetStartPoint_r';

{ const } function GEOSGeomGetEndPoint_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry): PGEOSGeometry; cdecl;
  external External_library name 'GEOSGeomGetEndPoint_r';

{ ***********************************************************************
  *
  *  Misc functions
  *
  ********************************************************************** }
{ Return 0 on exception, 1 otherwise }
{ const } function GEOSArea(g: PGEOSGeometry; area: PGEOSDouble): GEOSInt;
  cdecl; external External_library name 'GEOSArea';

{ const } function GEOSLength(g: PGEOSGeometry; length: PGEOSDouble): GEOSInt;
  cdecl; external External_library name 'GEOSLength';

{ const }  { const }
function GEOSDistance(g1: PGEOSGeometry; g2: PGEOSGeometry; dist: PGEOSDouble)
  : GEOSInt; cdecl; external External_library name 'GEOSDistance';

{ const }  { const }
function GEOSHausdorffDistance(g1: PGEOSGeometry; g2: PGEOSGeometry;
  dist: PGEOSDouble): GEOSInt; cdecl;
  external External_library name 'GEOSHausdorffDistance';

{ const }  { const }
function GEOSHausdorffDistanceDensify(g1: PGEOSGeometry; g2: PGEOSGeometry;
  densifyFrac: GEOSDouble; dist: PGEOSDouble): GEOSInt; cdecl;
  external External_library name 'GEOSHausdorffDistanceDensify';

{ const } function GEOSGeomGetLength(g: PGEOSGeometry; length: PGEOSDouble)
  : GEOSInt; cdecl; external External_library name 'GEOSGeomGetLength';

{ const } function GEOSArea_r(handle: GEOSContextHandle_t; g: PGEOSGeometry;
  area: PGEOSDouble): GEOSInt; cdecl;
  external External_library name 'GEOSArea_r';

{ const } function GEOSLength_r(handle: GEOSContextHandle_t; g: PGEOSGeometry;
  length: PGEOSDouble): GEOSInt; cdecl;
  external External_library name 'GEOSLength_r';

{ const }  { const }
function GEOSDistance_r(handle: GEOSContextHandle_t; g1: PGEOSGeometry;
  g2: PGEOSGeometry; dist: PGEOSDouble): GEOSInt; cdecl;
  external External_library name 'GEOSDistance_r';

{ const }  { const }
function GEOSHausdorffDistance_r(handle: GEOSContextHandle_t; g1: PGEOSGeometry;
  g2: PGEOSGeometry; dist: PGEOSDouble): GEOSInt; cdecl;
  external External_library name 'GEOSHausdorffDistance_r';

{ const }  { const }
function GEOSHausdorffDistanceDensify_r(handle: GEOSContextHandle_t;
  g1: PGEOSGeometry; g2: PGEOSGeometry; densifyFrac: GEOSDouble;
  dist: PGEOSDouble): GEOSInt; cdecl;
  external External_library name 'GEOSHausdorffDistanceDensify_r';

{ const } function GEOSGeomGetLength_r(handle: GEOSContextHandle_t;
  g: PGEOSGeometry; length: PGEOSDouble): GEOSInt; cdecl;
  external External_library name 'GEOSGeomGetLength_r';

{ Return 0 on exception, the closest points of the two geometries otherwise.
  * The first point comes from g1 geometry and the second point comes from g2.
}
{ const }  { const }
function GEOSNearestPoints(g1: PGEOSGeometry; g2: PGEOSGeometry)
  : PGEOSCoordSequence; cdecl;
  external External_library name 'GEOSNearestPoints';

{ const }  { const }
function GEOSNearestPoints_r(handle: GEOSContextHandle_t; g1: PGEOSGeometry;
  g2: PGEOSGeometry): PGEOSCoordSequence; cdecl;
  external External_library name 'GEOSNearestPoints_r';

{ ***********************************************************************
  *
  * Algorithms
  *
  ********************************************************************** }
{ Walking from A to B:
  *  return -1 if reaching P takes a counter-clockwise (left) turn
  *  return  1 if reaching P takes a clockwise (right) turn
  *  return  0 if P is collinear with A-B
  *
  * On exceptions, return 2.
  *
}
function GEOSOrientationIndex(Ax: GEOSDouble; Ay: GEOSDouble; Bx: GEOSDouble;
  By: GEOSDouble; Px: GEOSDouble; Py: GEOSDouble): GEOSInt; cdecl;
  external External_library name 'GEOSOrientationIndex';

function GEOSOrientationIndex_r(handle: GEOSContextHandle_t; Ax: GEOSDouble;
  Ay: GEOSDouble; Bx: GEOSDouble; By: GEOSDouble; Px: GEOSDouble;
  Py: GEOSDouble): GEOSInt; cdecl;
  external External_library name 'GEOSOrientationIndex_r';

{ ***********************************************************************
  *
  * Reader and Writer APIs
  *
  ********************************************************************** }

type
  GEOSWKTReader_t = GEOSWKTReader;
  GEOSWKTWriter_t = GEOSWKTWriter;
  GEOSWKBReader_t = GEOSWKBReader;
  GEOSWKBWriter_t = GEOSWKBWriter;
  { WKT Reader }

function GEOSWKTReader_create: PGEOSWKTReader; cdecl;
  external External_library name 'GEOSWKTReader_create';

procedure GEOSWKTReader_destroy(reader: PGEOSWKTReader); cdecl;
  external External_library name 'GEOSWKTReader_destroy';

{ const } function GEOSWKTReader_read(reader: PGEOSWKTReader; wkt: PGEOSChar)
  : PGEOSGeometry; cdecl; external External_library name 'GEOSWKTReader_read';

function GEOSWKTReader_create_r(handle: GEOSContextHandle_t): PGEOSWKTReader;
  cdecl; external External_library name 'GEOSWKTReader_create_r';

procedure GEOSWKTReader_destroy_r(handle: GEOSContextHandle_t;
  reader: PGEOSWKTReader); cdecl;
  external External_library name 'GEOSWKTReader_destroy_r';

{ const } function GEOSWKTReader_read_r(handle: GEOSContextHandle_t;
  reader: PGEOSWKTReader; wkt: PGEOSChar): PGEOSGeometry; cdecl;
  external External_library name 'GEOSWKTReader_read_r';

{ WKT Writer }
function GEOSWKTWriter_create: PGEOSWKTWriter; cdecl;
  external External_library name 'GEOSWKTWriter_create';

procedure GEOSWKTWriter_destroy(writer: PGEOSWKTWriter); cdecl;
  external External_library name 'GEOSWKTWriter_destroy';

{ const } function GEOSWKTWriter_write(writer: PGEOSWKTWriter; g: PGEOSGeometry)
  : PGEOSChar; cdecl; external External_library name 'GEOSWKTWriter_write';

procedure GEOSWKTWriter_setTrim(writer: PGEOSWKTWriter; trim: GEOSChar); cdecl;
  external External_library name 'GEOSWKTWriter_setTrim';

procedure GEOSWKTWriter_setRoundingPrecision(writer: PGEOSWKTWriter;
  precision: GEOSInt); cdecl;
  external External_library name 'GEOSWKTWriter_setRoundingPrecision';

procedure GEOSWKTWriter_setOutputDimension(writer: PGEOSWKTWriter;
  dim: GEOSInt); cdecl;
  external External_library name 'GEOSWKTWriter_setOutputDimension';

function GEOSWKTWriter_getOutputDimension(writer: PGEOSWKTWriter): GEOSInt;
  cdecl; external External_library name 'GEOSWKTWriter_getOutputDimension';

procedure GEOSWKTWriter_setOld3D(writer: PGEOSWKTWriter; useOld3D: GEOSInt);
  cdecl; external External_library name 'GEOSWKTWriter_setOld3D';

function GEOSWKTWriter_create_r(handle: GEOSContextHandle_t): PGEOSWKTWriter;
  cdecl; external External_library name 'GEOSWKTWriter_create_r';

procedure GEOSWKTWriter_destroy_r(handle: GEOSContextHandle_t;
  writer: PGEOSWKTWriter); cdecl;
  external External_library name 'GEOSWKTWriter_destroy_r';

{ const } function GEOSWKTWriter_write_r(handle: GEOSContextHandle_t;
  writer: PGEOSWKTWriter; g: PGEOSGeometry): PGEOSChar; cdecl;
  external External_library name 'GEOSWKTWriter_write_r';

procedure GEOSWKTWriter_setTrim_r(handle: GEOSContextHandle_t;
  writer: PGEOSWKTWriter; trim: GEOSChar); cdecl;
  external External_library name 'GEOSWKTWriter_setTrim_r';

procedure GEOSWKTWriter_setRoundingPrecision_r(handle: GEOSContextHandle_t;
  writer: PGEOSWKTWriter; precision: GEOSInt); cdecl;
  external External_library name 'GEOSWKTWriter_setRoundingPrecision_r';

procedure GEOSWKTWriter_setOutputDimension_r(handle: GEOSContextHandle_t;
  writer: PGEOSWKTWriter; dim: GEOSInt); cdecl;
  external External_library name 'GEOSWKTWriter_setOutputDimension_r';

function GEOSWKTWriter_getOutputDimension_r(handle: GEOSContextHandle_t;
  writer: PGEOSWKTWriter): GEOSInt; cdecl;
  external External_library name 'GEOSWKTWriter_getOutputDimension_r';

procedure GEOSWKTWriter_setOld3D_r(handle: GEOSContextHandle_t;
  writer: PGEOSWKTWriter; useOld3D: GEOSInt); cdecl;
  external External_library name 'GEOSWKTWriter_setOld3D_r';

{ WKB Reader }
function GEOSWKBReader_create: PGEOSWKBReader; cdecl;
  external External_library name 'GEOSWKBReader_create';

procedure GEOSWKBReader_destroy(reader: PGEOSWKBReader); cdecl;
  external External_library name 'GEOSWKBReader_destroy';

{ const } function GEOSWKBReader_read(reader: PGEOSWKBReader; wkb: PGEOSUChar;
  size: GEOSsize_t): PGEOSGeometry; cdecl;
  external External_library name 'GEOSWKBReader_read';

{ const } function GEOSWKBReader_readHEX(reader: PGEOSWKBReader;
  hex: PGEOSUChar; size: GEOSsize_t): PGEOSGeometry; cdecl;
  external External_library name 'GEOSWKBReader_readHEX';

function GEOSWKBReader_create_r(handle: GEOSContextHandle_t): PGEOSWKBReader;
  cdecl; external External_library name 'GEOSWKBReader_create_r';

procedure GEOSWKBReader_destroy_r(handle: GEOSContextHandle_t;
  reader: PGEOSWKBReader); cdecl;
  external External_library name 'GEOSWKBReader_destroy_r';

{ const } function GEOSWKBReader_read_r(handle: GEOSContextHandle_t;
  reader: PGEOSWKBReader; wkb: PGEOSUChar; size: GEOSsize_t): PGEOSGeometry;
  cdecl; external External_library name 'GEOSWKBReader_read_r';

{ const } function GEOSWKBReader_readHEX_r(handle: GEOSContextHandle_t;
  reader: PGEOSWKBReader; hex: PGEOSUChar; size: GEOSsize_t): PGEOSGeometry;
  cdecl; external External_library name 'GEOSWKBReader_readHEX_r';

{ WKB Writer }
function GEOSWKBWriter_create: PGEOSWKBWriter; cdecl;
  external External_library name 'GEOSWKBWriter_create';

procedure GEOSWKBWriter_destroy(writer: PGEOSWKBWriter); cdecl;
  external External_library name 'GEOSWKBWriter_destroy';

function GEOSWKBWriter_create_r(handle: GEOSContextHandle_t): PGEOSWKBWriter;
  cdecl; external External_library name 'GEOSWKBWriter_create_r';

procedure GEOSWKBWriter_destroy_r(handle: GEOSContextHandle_t;
  writer: PGEOSWKBWriter); cdecl;
  external External_library name 'GEOSWKBWriter_destroy_r';

{ The caller owns the results for these two methods! }
{ const } function GEOSWKBWriter_write(writer: PGEOSWKBWriter; g: PGEOSGeometry;
  size: PGEOSsize_t): PGEOSUChar; cdecl;
  external External_library name 'GEOSWKBWriter_write';

{ const } function GEOSWKBWriter_writeHEX(writer: PGEOSWKBWriter;
  g: PGEOSGeometry; size: PGEOSsize_t): PGEOSUChar; cdecl;
  external External_library name 'GEOSWKBWriter_writeHEX';

{ const } function GEOSWKBWriter_write_r(handle: GEOSContextHandle_t;
  writer: PGEOSWKBWriter; g: PGEOSGeometry; size: PGEOSsize_t): PGEOSUChar;
  cdecl; external External_library name 'GEOSWKBWriter_write_r';

{ const } function GEOSWKBWriter_writeHEX_r(handle: GEOSContextHandle_t;
  writer: PGEOSWKBWriter; g: PGEOSGeometry; size: PGEOSsize_t): PGEOSUChar;
  cdecl; external External_library name 'GEOSWKBWriter_writeHEX_r';

{
  * Specify whether output WKB should be 2d or 3d.
  * Return previously set number of dimensions.
}
{ const } function GEOSWKBWriter_getOutputDimension(writer: PGEOSWKBWriter)
  : GEOSInt; cdecl;
  external External_library name 'GEOSWKBWriter_getOutputDimension';

procedure GEOSWKBWriter_setOutputDimension(writer: PGEOSWKBWriter;
  newDimension: GEOSInt); cdecl;
  external External_library name 'GEOSWKBWriter_setOutputDimension';

{ const } function GEOSWKBWriter_getOutputDimension_r
  (handle: GEOSContextHandle_t; writer: PGEOSWKBWriter): GEOSInt; cdecl;
  external External_library name 'GEOSWKBWriter_getOutputDimension_r';

procedure GEOSWKBWriter_setOutputDimension_r(handle: GEOSContextHandle_t;
  writer: PGEOSWKBWriter; newDimension: GEOSInt); cdecl;
  external External_library name 'GEOSWKBWriter_setOutputDimension_r';

{
  * Specify whether the WKB byte order is big or little endian.
  * The return value is the previous byte order.
}
{ const } function GEOSWKBWriter_getByteOrder(writer: PGEOSWKBWriter): GEOSInt;
  cdecl; external External_library name 'GEOSWKBWriter_getByteOrder';

procedure GEOSWKBWriter_setByteOrder(writer: PGEOSWKBWriter;
  byteOrder: GEOSInt); cdecl;
  external External_library name 'GEOSWKBWriter_setByteOrder';

{ const } function GEOSWKBWriter_getByteOrder_r(handle: GEOSContextHandle_t;
  writer: PGEOSWKBWriter): GEOSInt; cdecl;
  external External_library name 'GEOSWKBWriter_getByteOrder_r';

procedure GEOSWKBWriter_setByteOrder_r(handle: GEOSContextHandle_t;
  writer: PGEOSWKBWriter; byteOrder: GEOSInt); cdecl;
  external External_library name 'GEOSWKBWriter_setByteOrder_r';

{
  * Specify whether SRID values should be output.
}
{ const } function GEOSWKBWriter_getIncludeSRID(writer: PGEOSWKBWriter)
  : GEOSChar; cdecl;
  external External_library name 'GEOSWKBWriter_getIncludeSRID';

{ const } procedure GEOSWKBWriter_setIncludeSRID(writer: PGEOSWKBWriter;
  writeSRID: GEOSChar); cdecl;
  external External_library name 'GEOSWKBWriter_setIncludeSRID';

{ const } function GEOSWKBWriter_getIncludeSRID_r(handle: GEOSContextHandle_t;
  writer: PGEOSWKBWriter): GEOSChar; cdecl;
  external External_library name 'GEOSWKBWriter_getIncludeSRID_r';

{ const } procedure GEOSWKBWriter_setIncludeSRID_r(handle: GEOSContextHandle_t;
  writer: PGEOSWKBWriter; writeSRID: GEOSChar); cdecl;
  external External_library name 'GEOSWKBWriter_setIncludeSRID_r';

{
  * Free buffers returned by stuff like GEOSWKBWriter_write(),
  * GEOSWKBWriter_writeHEX() and GEOSWKTWriter_write().
}
procedure GEOSFree(buffer: pointer); cdecl;
  external External_library name 'GEOSFree';

procedure GEOSFree_r(handle: GEOSContextHandle_t; buffer: pointer); cdecl;
  external External_library name 'GEOSFree_r';


implementation

end.

