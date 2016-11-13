# encoding:utf-8
module V3
  class DilianApi < Grape::API
    format :json

    desc "帝联通知接口"
    post :report_transcode do
      #{"userID":"69W4q7PtfildHt9a","account":"test","filePath":"/input/aaaa.mp4","size":"xxxxxxxxxx",
      #"profile_name":"xxx","tm":"1432829431","type":"xxxxxx","result":"xxxxxx","src_url":"xxxxxx","url":"xxxxxx","snapshot_url":"xxxxxx","signature":"xxxxxxxxxxxx"}
      signature = params[:signature]
      return {ret: -1, message: "par err"} unless params[:result] == "success"
      return {ret: -1, message: "par err"} unless params[:url].present?
      app_sign = Digest::MD5.hexdigest("dilian:OGLsna00sIw76IR98&subject_id:#{params[:subject_id]}&storage_url:#{params[:storage_url]}").downcase
      #http://h.owhat.cn/release/14-1461738387_flv/14-1461738387.mp4
      subject_id = params[:url].gsub("http://h.owhat.cn/release/", "").split("/")[0].split("-")[0]

      if signature != app_sign
        subject = Shop::Subject.find_by(id: subject_id)
        return fail(0, "找不到该流") unless subject.present?
        if subject.update(storage_url: params[:url], status: 2)
          CoreLogger.info(logger_format(api: "report_transcode", subject_id: subject_id, storage_url: params[:url]))
          return success({ ret: "0", message: "ok"})# 更新成功
        else
          return success({ ret: "-2", message: "internal err" })
        end
      else
        return success({ ret: "-2", message: "internal err" })
      end
    end

  end
end
