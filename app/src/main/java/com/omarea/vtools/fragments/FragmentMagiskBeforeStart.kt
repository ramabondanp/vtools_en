package com.omarea.vtools.fragments

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.fragment.app.Fragment
import com.omarea.common.shared.FileWrite
import com.omarea.common.shared.MagiskExtend
import com.omarea.vtools.databinding.FragmentMagiskBeforestartBinding
import java.io.File

class FragmentMagiskBeforeStart : Fragment() {
    private var _binding: FragmentMagiskBeforestartBinding? = null
    private val binding get() = _binding!!

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentMagiskBeforestartBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        binding.magiskBeforestart.setText(MagiskExtend.getFsPostDataSH())
        binding.magiskBeforestartReset.setOnClickListener {
            binding.magiskBeforestart.setText(MagiskExtend.getFsPostDataSH())
        }
        binding.magiskBeforestartSave.setOnClickListener {
            val context = requireContext()
            if (FileWrite.writePrivateFile((binding.magiskBeforestart.text.toString() + "\n").toByteArray(), "magisk_post-fs-data.sh", context)) {
                val file = FileWrite.getPrivateFilePath(context, "magisk_post-fs-data.sh")
                if (MagiskExtend.updateFsPostDataSH(file)) {
                    binding.magiskBeforestart.setText(MagiskExtend.getFsPostDataSH())
                    Toast.makeText(context, "Changes saved. Take effect after reboot.", Toast.LENGTH_LONG).show()
                    File(file).delete()
                } else {
                    Toast.makeText(context, "Magisk image has insufficient space. Operation failed.", Toast.LENGTH_LONG).show()
                }
            } else {
                Toast.makeText(context, "Save failed.", Toast.LENGTH_LONG).show()
            }
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
